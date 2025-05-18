# ============================================================
#              Maxent 物种分布模型构建与分析
#     —— 输入：筛选后环境变量 TIF + 清洗物种点 CSV
#     —— 输出：模型、预测图、响应曲线、变量重要性报告
# ============================================================

# ------------------------------------------------------------
# 0. 环境清理与依赖加载
# ------------------------------------------------------------

## 0.1 清理环境（每次运行前强烈建议）
rm(list = ls())
if (!is.null(dev.list())) dev.off()
cat("\014"); gc()

## 0.2 加载依赖包
library(terra)
library(maxnet)
library(dplyr)
library(ggplot2)
library(showtext)
library(ENMeval)

## 0.3 加载中文字体（如需中文制图，仅需一次）
showtext_auto(enable = TRUE)
font_add(family = "myfont", regular = "/System/Library/Fonts/STHeiti Medium.ttc")

# ------------------------------------------------------------
# 1. 路径配置（所有路径均为 test/T- 前缀目录）
# ------------------------------------------------------------

base_dir      <- "/Volumes/Rui's Mac/two_species/test"
env_tif_dir   <- file.path(base_dir, "T-cor_analysis/selected_env_tif")   # 筛选后环境变量
occ_dir       <- file.path(base_dir, "T-cleaned_points")                  # 清洗后物种点
output_dir    <- file.path(base_dir, "T-model_output")
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# ------------------------------------------------------------
# 2. 加载环境变量栅格
# ------------------------------------------------------------

env_files  <- list.files(env_tif_dir, pattern = "\\.tif$", full.names = TRUE)
env_stack  <- rast(env_files)
cat("📦 加载环境变量栅格，共", length(env_files), "层\n")

# ------------------------------------------------------------
# 3. 读取物种出现点数据
# ------------------------------------------------------------

species   <- "Am.languida"    # 可修改为当前建模的物种名
occ_file  <- file.path(occ_dir, paste0(species, "_cleaned.csv"))
occ_data  <- read.csv(occ_file)
if (!all(c("lon", "lat") %in% colnames(occ_data))) {
  stop("❌ 出现点文件缺少 lon/lat 字段！")
}
cat("📍 加载物种出现点，共", nrow(occ_data), "个点\n")

# ------------------------------------------------------------
# 4. 生成背景点
# ------------------------------------------------------------

set.seed(123)
bg_points <- spatSample(env_stack[[1]], size = 10000, method = "random", na.rm = TRUE, as.points = TRUE)
bg_df     <- terra::geom(bg_points)[, c("x", "y")]
colnames(bg_df) <- c("lon", "lat")
cat("🌱 生成背景点，共", nrow(bg_df), "个\n")

# ------------------------------------------------------------
# 5. 提取环境变量值（出现点 + 背景点）
# ------------------------------------------------------------

occ_vals <- terra::extract(env_stack, occ_data[, c("lon", "lat")])
bg_vals  <- terra::extract(env_stack, bg_df)

# 构造训练数据
occ_env_vals   <- occ_vals[, -1]  # 去除ID列
bg_env_vals    <- bg_vals         # 背景点无ID列
common_cols    <- intersect(names(occ_env_vals), names(bg_env_vals))
occ_env_vals   <- occ_env_vals[, common_cols]
bg_env_vals    <- bg_env_vals[, common_cols]
train_data     <- rbind(
  data.frame(pa = 1, occ_env_vals),
  data.frame(pa = 0, bg_env_vals)
)
train_data     <- na.omit(train_data)
cat("🚦 构建训练数据，剩余", nrow(train_data), "条记录\n")

# ------------------------------------------------------------
# 6. ENMevaluate 自动调参 + Maxnet 建模
# ------------------------------------------------------------

tune.args <- list(fc = c("L", "LQ", "LQH", "H"), rm = seq(0.5, 2, 0.5))
cat("⚙️ 开始 ENMevaluate 自动调参...\n")
eval_res <- ENMevaluate(
  occs       = occ_data[, c("lon", "lat")],
  envs       = env_stack,
  bg         = bg_df,
  tune.args  = tune.args,
  partitions = "block",
  algorithm  = "maxnet",
  overlap    = TRUE
)
best_row <- eval_res@results[which.min(eval_res@results$delta.AICc), ]
rm_best  <- best_row$rm
fc_best  <- best_row$fc

cat("✅ 调参完成，最优正则化倍数 rm_best =", rm_best, "\n")
cat("✅ 最优特征类型 fc_best =", fc_best, "\n")

write.csv(data.frame(rm_best = rm_best, fc_best = fc_best),
          file.path(output_dir, paste0(species, "_optimal_params.csv")),
          row.names = FALSE)

fc_best <- tolower(fc_best)
rm_best <- as.numeric(as.character(rm_best))
fit     <- maxnet(p = train_data$pa,
                  data = train_data[, -1],
                  f    = maxnet.formula(train_data$pa, train_data[, -1], classes = fc_best),
                  regmult = rm_best)
cat("✅ 使用最优参数重新训练 maxnet 模型完成\n")

# ------------------------------------------------------------
# 7. 预测栅格概率（批量处理）
# ------------------------------------------------------------

env_vals   <- as.data.frame(env_stack, xy = FALSE, na.rm = FALSE)
valid_idx  <- complete.cases(env_vals)
pred_vals  <- rep(NA, nrow(env_vals))
pred_vals[valid_idx] <- predict(fit, env_vals[valid_idx, ], type = "cloglog")
pred_rast  <- env_stack[[1]]
values(pred_rast) <- pred_vals

output_pred <- file.path(output_dir, paste0(species, "_prediction.tif"))
writeRaster(pred_rast, filename = output_pred, overwrite = TRUE)
cat("🌍 预测概率栅格输出：", output_pred, "\n")

# ------------------------------------------------------------
# 8. 响应曲线绘制
# ------------------------------------------------------------

plot_response <- function(model, varname, data) {
  var_seq <- seq(min(data[[varname]], na.rm = TRUE), max(data[[varname]], na.rm = TRUE), length.out = 100)
  newdata <- data[rep(1, 100), , drop = FALSE]
  newdata[[varname]] <- var_seq
  preds <- predict(model, newdata, type = "cloglog")
  df <- data.frame(value = var_seq, prediction = preds)
  ggplot(df, aes(x = value, y = prediction)) +
    geom_line() +
    labs(title = paste("响应曲线:", varname), x = varname, y = "预测概率")
}

png(file.path(output_dir, paste0(species, "_response_curves_manual.png")), width = 1000, height = 800)
for (v in colnames(train_data)[-1]) {
  png(file.path(output_dir, paste0(species, "_response_curve_", v, ".png")), width = 1000, height = 800)
  print(plot_response(fit, v, train_data[, -1]))
  dev.off()
}
cat("📈 响应曲线（手动绘制）已保存\n")

# ------------------------------------------------------------
# 9. Jackknife 变量重要性分析
# ------------------------------------------------------------

train_gain <- function(model, data) {
  occ_data <- data[data$pa == 1, , drop = FALSE]
  preds    <- predict(model, occ_data[, -1], type = "logistic")
  mean(log(preds))
}

all_vars <- colnames(train_data)[-1]
gain_full <- train_gain(fit, train_data)

jackknife_results <- data.frame(variable = all_vars, gain_only = NA_real_, gain_without = NA_real_)
for (v in all_vars) {
  cat("👉 正在处理变量：", v, "\n")
  try({
    mod_only <- maxnet(p = train_data$pa, data = train_data[, v, drop = FALSE],
                       f = maxnet.formula(train_data$pa, train_data[, v, drop = FALSE]), classes = "lqh")
    jackknife_results$gain_only[jackknife_results$variable == v] <- train_gain(mod_only, train_data)
  }, silent = TRUE)
  vars_wo <- setdiff(all_vars, v)
  if (length(vars_wo) == 0) {
    cat("  ⚠️ 去除所有变量后无剩余变量，跳过去除变量建模\n")
    jackknife_results$gain_without[jackknife_results$variable == v] <- NA_real_
    next
  }
  try({
    mod_wo <- maxnet(p = train_data$pa, data = train_data[, vars_wo, drop = FALSE],
                     f = maxnet.formula(train_data$pa, train_data[, vars_wo, drop = FALSE]), classes = "lqh")
    jackknife_results$gain_without[jackknife_results$variable == v] <- train_gain(mod_wo, train_data)
  }, silent = TRUE)
}
jackknife_results$gain_full <- gain_full
write.csv(jackknife_results, file.path(output_dir, paste0(species, "_jackknife.csv")), row.names = FALSE)
cat("📊 Jackknife 变量重要性结果已保存\n")

# 画 Jackknife 变量重要性柱状图
# 转成长表以便 ggplot 柱状图
library(tidyr)
jackknife_long <- jackknife_results %>%
  pivot_longer(cols = c(gain_only, gain_without, gain_full),
               names_to = "type", values_to = "gain")

jackknife_long_clean <- jackknife_long %>% filter(!is.na(gain))
ggplot(jackknife_long_clean, aes(x = variable, y = gain, fill = type)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.2), width = 0.3) +
  coord_flip() +
  labs(title = paste(species, "Jackknife变量重要性"), y = "训练增益", x = "变量") +
  theme_minimal() +
  theme(
    text = element_text(family = "myfont"),
    axis.text.y = element_text(size = 12),
    axis.text.x = element_text(size = 10)
  )
dev.off()
cat("📊 横向Jackknife变量重要性图已保存\n")

# ============================================================
# 备注：
# - 该脚本基于 maxnet 包，适合批量单物种建模。
# - 变量类型及缺失值均已处理。
# - 建议根据实际数据调整背景点数量、正则化参数（regmult）和特征类型（classes）。
# - 响应曲线和Jackknife分析为基础版本，可根据需要丰富。
# - 输出路径和文件名请根据项目目录结构适当调整。
# ============================================================
