# ===========================================================
# 物种出现点 CSV 批量清洗与标准化脚本
# —— 推荐每次运行前自动清理 R 环境
# ===========================================================

# -----------------------------------------------------------
# 0. 清理 R 环境（强烈建议每次执行前）
# -----------------------------------------------------------
rm(list = ls())                         # 清空所有对象
if (!is.null(dev.list())) dev.off()     # 关闭图形设备
cat("\014")                             # 清屏
gc()                                    # 回收内存

# -----------------------------------------------------------
# 1. 依赖包自动安装并加载
# -----------------------------------------------------------
packages  <- c("dplyr", "readr", "sf")  # 依赖包列表
new_pkgs  <- packages[!(packages %in% installed.packages()[, "Package"])]
if (length(new_pkgs)) install.packages(new_pkgs)
lapply(packages, library, character.only = TRUE)

# -----------------------------------------------------------
# 2. 路径与物种配置
# -----------------------------------------------------------
base_dir   <- "/Volumes/Rui's Mac/two_species/test"
input_dir  <- file.path(base_dir, "T-occurrences")
output_dir <- file.path(base_dir, "T-cleaned_points")                # 清洗后输出目录
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)      # 自动创建输出目录（如不存在）

species_files <- c("Am.languida.csv", "Az.dexteroporum.csv")        # 原始物种 CSV 文件名
species_names <- c("Am.languida", "Az.dexteroporum")                # 物种名称（与文件顺序对应）

# ===========================================================
# 3. 物种批量处理主循环
# ===========================================================
for (i in seq_along(species_files)) {
  # ---------------------------------------------------------
  # 3.1. 读取原始数据
  # ---------------------------------------------------------
  input_path <- file.path(input_dir, species_files[i])
  sp_name    <- species_names[i]
  raw        <- read_csv(input_path, show_col_types = FALSE)
  
  # ---------------------------------------------------------
  # 3.2. 字段名标准化与检查
  # ---------------------------------------------------------
  colnames(raw) <- tolower(colnames(raw))    # 全部列名小写，便于后续操作
  if (!all(c("longitude", "latitude") %in% names(raw))) {
    stop(paste0("❌ 文件 ", species_files[i], " 缺少 Longitude/Latitude 字段"))
  }
  
  # ---------------------------------------------------------
  # 3.3. 清洗与标准化
  #      （去重、去NA、加物种名）
  # ---------------------------------------------------------
  cleaned <- raw %>%
    select(lon = longitude, lat = latitude) %>%   # 仅保留经纬度，并重命名
    filter(!is.na(lon) & !is.na(lat)) %>%         # 去除缺失值
    distinct() %>%                                # 去重
    mutate(species = sp_name) %>%                 # 增加物种名列
    select(species, lon, lat)                     # 保持列顺序一致
  
  cat("✅", sp_name, "：有效点位", nrow(cleaned), "\n")
  
  # ---------------------------------------------------------
  # 3.4. 保存为标准 CSV
  # ---------------------------------------------------------
  write_csv(cleaned, file.path(output_dir, paste0(sp_name, "_cleaned.csv")))
  
  # ---------------------------------------------------------
  # 3.5. 导出为 Shapefile（WGS84 坐标）
  # ---------------------------------------------------------
  shp <- st_as_sf(cleaned, coords = c("lon", "lat"), crs = 4326)
  st_write(shp, dsn = file.path(output_dir, paste0(sp_name, "_cleaned.shp")),
           delete_layer = TRUE, quiet = TRUE)
}

# -----------------------------------------------------------
# 批量清洗结束，输出完成提示
# -----------------------------------------------------------
cat("\n🎉 物种点清洗全部完成，标准化结果已输出到：", output_dir, "\n")
