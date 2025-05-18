# ===========================================================
# Maxent建模HTML报告自动生成脚本
# —— 根据指定物种批量输出HTML报告
# —— 需配合 T-scripts/maxent_report.Rmd 模板
# ===========================================================

# -----------------------------------------------------------
# 0. 环境清理与依赖加载
# -----------------------------------------------------------
rm(list = ls())
if (!is.null(dev.list())) dev.off()
cat("\014"); gc()

library(rmarkdown)
# -----------------------------------------------------------
# 1. 读取概率预测栅格
# -----------------------------------------------------------
library(terra)

# 路径根据你的结构调整
tif_path <- "/Volumes/Rui's Mac/two_species/test/T-model_output/Am.languida_prediction.tif"
png_path <- "/Volumes/Rui's Mac/two_species/test/T-model_output/Am.languida_prediction.png"

if (file.exists(tif_path)) {
  r <- rast(tif_path)
  
# -----------------------------------------------------------
# 2. 绘制并保存为PNG图片
# -----------------------------------------------------------
  png(png_path, width=2000, height=1800, res=220)
  plot(
    r,
    main = "Am.languida Predicted Probability",
    col = hcl.colors(100, "YlGnBu", rev = TRUE),  # 你可以根据需要调整色带
    axes = FALSE,
    legend = TRUE
  )
  dev.off()
  cat("✅ 预测概率PNG已输出：", png_path, "\n")
} else {
  cat("❌ 没有找到TIF文件：", tif_path, "\n")
}

# -----------------------------------------------------------
# 3. 参数设置（物种名、目录等）
# -----------------------------------------------------------
species <- "Am.languida"    # 改成你想生成报告的物种名

base_dir   <- "/Volumes/Rui's Mac/two_species/test"
output_dir <- file.path(base_dir, "T-model_output")
report_rmd <- file.path(base_dir, "T-scripts/maxent_report.Rmd")
report_html <- file.path(output_dir, paste0(species, "_maxent_report.html"))

# -----------------------------------------------------------
# 4. 渲染Rmarkdown生成HTML报告
# -----------------------------------------------------------
if (file.exists(report_rmd)) {
  rmarkdown::render(
  input = report_rmd,
  output_file = report_html,
  params = list(
    species = species,
    scientific_name = "Dexteroporum az.",
    region = "南海北部",
    occurrence_count = 42,
    model_dir = ".",  # 当前就是 output_dir 了
    response_pattern = paste0("^", species, "_response_curve_.*\\.png$"),
    response_curve_dir = ".",  # <—— 改这个
    jackknife_plot = paste0(species, "_jackknife_plot_horizontal.png"), 
    optimal_params = paste0(species, "_optimal_params.csv"),
    jackknife_table = paste0(species, "_jackknife.csv"),
    prediction_raster_path = paste0(species, "_prediction.png"),
    extra_figures_dir = "./"  # <—— 改这个
  ),
  knit_root_dir = output_dir,
  envir = new.env()
)
  cat("📝 Maxent HTML报告已输出：", report_html, "\n")
} else {
  cat("⚠️ 未检测到Rmd模板：", report_rmd, "\n")
}

# -----------------------------------------------------------
# 备注
# -----------------------------------------------------------
# - 请确保 T-scripts/maxent_report.Rmd 模板存在，并根据项目需求自定义报告内容。
# - 支持自动整合响应曲线、Jackknife重要性图、参数表等。
# - 仅需修改 species 即可复用，建议所有物种建模结果都用该脚本生成统一报告。
# ===========================================================
