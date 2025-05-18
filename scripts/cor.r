# ===========================================================
#           环境变量相关性分析与变量筛选（批量处理）
#    —— 全流程，输出到 test/T-cor_analysis 及其子目录 ——
# ===========================================================

# -----------------------------------------------------------
# 0. 环境清理与依赖加载
# -----------------------------------------------------------
## 0.1 清理环境，保证每次运行前环境“干净”
rm(list = ls())
if (!is.null(dev.list())) dev.off()
cat("\014"); gc()

# -----------------------------------------------------------
# 1. 路径与输出目录准备
# -----------------------------------------------------------
## 1.1 输出主目录（test/T-cor_analysis），不存在自动创建
cor_dir <- "/Volumes/Rui's Mac/two_species/test/T-cor_analysis"
if (!dir.exists(cor_dir)) dir.create(cor_dir, recursive = TRUE)

# -----------------------------------------------------------
# 2. 环境变量相关性分析：数据抽样与合并
# -----------------------------------------------------------
library(terra)
library(dplyr)
library(ggplot2)
library(corrplot)

## 2.1 环境变量 TIF 文件目录（test/T-env_layers_tif）
tif_dir <- "/Volumes/Rui's Mac/two_species/test/T-env_layers_tif"
tif_files <- list.files(tif_dir, pattern = "\\.tif$", full.names = TRUE)
var_names <- tools::file_path_sans_ext(basename(tif_files))

## 2.2 合并所有 TIF 为多层 SpatRaster，并过滤无效文件
rasters <- lapply(tif_files, terra::rast)
valid_idx <- vapply(rasters, function(x) inherits(x, "SpatRaster"), logical(1))
cat("有效栅格数：", sum(valid_idx), "/", length(rasters), "\n")
if (!all(valid_idx)) {
  cat("⚠️ 有无效或损坏的 tif 文件，将被忽略：\n")
  print(basename(tif_files[!valid_idx]))
}
rasters_stack <- rast(rasters[valid_idx])
names(rasters_stack) <- var_names[valid_idx]

## 2.3 随机抽样像元，去除NA，抽样表后续用于相关性分析
set.seed(42)
n_samp <- 10000
vals <- spatSample(rasters_stack, size = n_samp, method = "random", na.rm = TRUE, as.data.frame = TRUE)
cat("✅ 已合成抽样变量表，变量有：", paste(colnames(vals), collapse = ", "), "\n")

## 2.4 可选：输出抽样结果表，便于复查
write.csv(vals, file = file.path(cor_dir, "env_variables_sample.csv"), row.names = FALSE)

# -----------------------------------------------------------
# 3. 相关性矩阵与强相关变量筛查
# -----------------------------------------------------------
## 3.1 计算 Pearson 相关系数矩阵，完整输出
cor_matrix <- cor(vals, use = "complete.obs", method = "pearson")
write.csv(cor_matrix, file = file.path(cor_dir, "cor_matrix.csv"))

## 3.2 绘制相关性热图
corrplot::corrplot(cor_matrix, method = "color", type = "upper", tl.cex = 0.8)

## 3.3 强相关变量筛查（|r|>0.7），终端提示并输出变量对
high_cor_pairs <- which(abs(cor_matrix) > 0.7 & abs(cor_matrix) < 1, arr.ind = TRUE)
if (length(high_cor_pairs) > 0) {
  cat("\n⚠️ 存在强相关变量对（|r|>0.7）：\n")
  print(data.frame(
    var1 = rownames(cor_matrix)[high_cor_pairs[, 1]],
    var2 = colnames(cor_matrix)[high_cor_pairs[, 2]],
    r = cor_matrix[high_cor_pairs]
  ))
} else {
  cat("✅ 无强相关变量对，全部可用于建模\n")
}

# -----------------------------------------------------------
# 4. 相关性阈值筛选与变量名单生成
# -----------------------------------------------------------
## 4.1 阈值可自定义，默认0.85。自动剔除每对强相关中的第二个变量
cor_threshold <- 0.85
high_cor_pairs <- which(abs(cor_matrix) > cor_threshold & abs(cor_matrix) < 1, arr.ind = TRUE)

if (length(high_cor_pairs) > 0) {
  cat(sprintf("\n⚠️ 存在强相关变量对（|r|>%.2f）：\n", cor_threshold))
  print(data.frame(
    var1 = rownames(cor_matrix)[high_cor_pairs[, 1]],
    var2 = colnames(cor_matrix)[high_cor_pairs[, 2]],
    r = cor_matrix[high_cor_pairs]
  ))
  vars_to_remove <- unique(colnames(cor_matrix)[high_cor_pairs[, 2]])
  all_vars <- colnames(cor_matrix)
  selected_vars <- setdiff(all_vars, vars_to_remove)
  cat("\n✅ 自动筛选后保留变量：\n")
  print(selected_vars)
  writeLines(selected_vars, file.path(cor_dir, "selected_vars.txt"))
} else {
  cat(sprintf("✅ 无强相关变量对（|r|>%.2f），全部可用于建模\n", cor_threshold))
  writeLines(colnames(cor_matrix), file.path(cor_dir, "selected_vars.txt"))
}

# -----------------------------------------------------------
# 5. 筛选变量文件自动拷贝到新目录（tif/asc）
# -----------------------------------------------------------
## 5.1 路径设置，原始文件来自 test/T-env_layers_tif 和 test/T-env_layers_asc
selected_vars_file <- file.path(cor_dir, "selected_vars.txt")
selected_vars <- readLines(selected_vars_file)
tif_src_dir <- "/Volumes/Rui's Mac/two_species/test/T-env_layers_tif"
asc_src_dir <- "/Volumes/Rui's Mac/two_species/test/T-env_layers_asc"
tif_dst_dir <- file.path(cor_dir, "selected_env_tif")
asc_dst_dir <- file.path(cor_dir, "selected_env_asc")
dir.create(tif_dst_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(asc_dst_dir, showWarnings = FALSE, recursive = TRUE)

## 5.2 批量拷贝所有保留变量的 TIF/ASC 文件到对应子文件夹
for (var in selected_vars) {
  tif_src <- file.path(tif_src_dir, paste0(var, ".tif"))
  tif_dst <- file.path(tif_dst_dir, paste0(var, ".tif"))
  if (file.exists(tif_src)) {
    file.copy(tif_src, tif_dst, overwrite = TRUE)
    cat("✅ 拷贝 TIF：", tif_src, "\n")
  } else {
    cat("⚠️ 缺失 TIF 文件：", tif_src, "\n")
  }
}
for (var in selected_vars) {
  asc_src <- file.path(asc_src_dir, paste0(var, ".asc"))
  asc_dst <- file.path(asc_dst_dir, paste0(var, ".asc"))
  if (file.exists(asc_src)) {
    file.copy(asc_src, asc_dst, overwrite = TRUE)
    cat("✅ 拷贝 ASC：", asc_src, "\n")
  } else {
    cat("⚠️ 缺失 ASC 文件：", asc_src, "\n")
  }
}

## 5.3 最终校验，确保所有 ASC 文件均已拷贝成功
asc_dst_files <- list.files(asc_dst_dir, pattern = "\\.asc$", full.names = FALSE)
asc_dst_names <- tools::file_path_sans_ext(asc_dst_files)
missing_asc <- setdiff(selected_vars, asc_dst_names)
if(length(missing_asc) == 0) {
  cat("✅ 所有筛选变量对应的 ASC 文件均已成功拷贝！\n")
} else {
  cat("⚠️ 缺少以下 ASC 文件：\n")
  print(missing_asc)
}

cat("\n🎉 环境变量文件筛选整理完成！\n")
cat("筛选后的TIF目录：", tif_dst_dir, "\n")
cat("筛选后的ASC目录：", asc_dst_dir, "\n")

