# ===========================================================
#        NetCDF → 统一裁剪/重采样 → TIF/ASC（批量处理）
#     —— 全流程，全部用 terra 包，输出到指定文件夹 ——
# ===========================================================

# -----------------------------------------------------------
# 0. 环境清理与依赖加载
# -----------------------------------------------------------

## 0.1 清理环境
rm(list = ls())                          # 清空对象
if (!is.null(dev.list())) dev.off()      # 关闭图形设备
cat("\014"); gc()                        # 清屏并回收内存

## 0.2 加载依赖
library(terra)                           # 空间栅格主包
library(tools)                           # 文件操作辅助

# -----------------------------------------------------------
# 1. 路径与文件夹准备
# -----------------------------------------------------------

## 1.1 路径设置
base_dir <- "/Volumes/Rui's Mac/two_species/test"              # 项目主目录
env_dir  <- file.path(base_dir, "T-envir")                     # 原始 nc/tif 数据目录
tif_dir  <- file.path(base_dir, "T-env_layers_tif")            # TIF 输出目录
asc_dir  <- file.path(base_dir, "T-env_layers_asc")            # ASC 输出目录

## 1.2 输出目录创建
dir.create(tif_dir, showWarnings = FALSE, recursive = TRUE) # 自动创建 TIF 目录
dir.create(asc_dir, showWarnings = FALSE, recursive = TRUE) # 自动创建 ASC 目录

# -----------------------------------------------------------
# 2. 区域与裁剪范围设置
# -----------------------------------------------------------

## 2.1 空间范围
crop_extent <- ext(105, 130, 15, 45)       # 裁剪范围（terra 的 ext）

# -----------------------------------------------------------
# 3. 基准栅格裁剪与输出
# -----------------------------------------------------------

## 3.1 读取并裁剪 distance-from-shore.tif
ref_raster_path <- file.path(env_dir, "distance-from-shore.tif")
ref_r0 <- rast(ref_raster_path)                     # 读取参考栅格
ref_crop <- crop(ref_r0, crop_extent)               # 裁剪到目标范围

## 3.2 输出标准 distance.tif
distance_out <- file.path(tif_dir, "distance.tif")
writeRaster(ref_crop, distance_out, overwrite = TRUE, NAflag = -9999)
cat("✅ 已裁剪并输出 distance.tif：", distance_out, "\n")

## 3.3 读取为对齐基准
ref <- rast(distance_out)                           # 作为对齐基准

# -----------------------------------------------------------
# 4. 批量裁剪每个 NetCDF 文件，输出 TIF
# -----------------------------------------------------------

## 4.1 遍历所有 nc 文件并处理
nc_files <- list.files(env_dir, pattern = "\\.nc$", full.names = TRUE)
for (nc_path in nc_files) {
  # 4.1.1 文件名与变量名处理
  var_name   <- file_path_sans_ext(basename(nc_path))
  short_name <- strsplit(var_name, "_")[[1]][1]
  cat("🔄 处理：", var_name, "→", short_name, "\n")
  
  # 4.1.2 读取 nc 文件
  r0 <- try(rast(nc_path), silent = TRUE)
  if (inherits(r0, "try-error")) {
    cat("⚠️ 无法读取：", var_name, "\n")
    next
  }
  
  # 4.1.3 裁剪并重采样到参考栅格
  r_crop <- crop(r0, crop_extent)
  r_res <- resample(r_crop, ref, method = "bilinear")
  
  # 4.1.4 输出为 tif
  tif_path <- file.path(tif_dir, paste0(short_name, ".tif"))
  writeRaster(r_res, tif_path, overwrite = TRUE, NAflag = -9999)
  cat("✅ 已输出 TIF：", tif_path, "\n")
}

# -----------------------------------------------------------
# 5. TIF → ASC 批量转换
# -----------------------------------------------------------

## 5.1 遍历所有 tif 文件并转换为 ASC
tif_files <- list.files(tif_dir, pattern = "\\.tif$", full.names = TRUE)
for (tif in tif_files) {
  r <- rast(tif)
  asc_name <- paste0(tools::file_path_sans_ext(basename(tif)), ".asc")
  asc_path <- file.path(asc_dir, asc_name)
  writeRaster(r, asc_path, overwrite = TRUE, NAflag = -9999)
  cat("✅ 已输出 ASC：", asc_path, "\n")
}

# -----------------------------------------------------------
# 6. 空间一致性检查（TIF）
# -----------------------------------------------------------

## 6.1 检查所有 tif 文件空间一致性
cat("🔍 检查所有 tif 空间一致性...\n")
rlist <- lapply(tif_files, rast)
ok <- try(all(sapply(rlist, function(x)
    compareGeom(x, ref, stopOnError = FALSE))), silent = TRUE)
if (isTRUE(ok)) {
  cat("✅ 所有 TIF 空间一致！\n")
} else {
  stop("❌ 检查失败：TIF 文件空间参数不一致，请检查！")
}

## 6.2 流程完成提示
cat("🎉 terra 测试流程全部完成，TIF/ASC 输出至：", tif_dir, "和", asc_dir, "\n")
