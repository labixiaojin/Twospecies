<p align="center">
  <strong>📍 Maxent 预测输出展示图</strong><br/>
  <img src="T-model_output/Am.languida_prediction.png" alt="Am.languida预测图" width="45%" style="margin:10px;"/>
  <img src="T-model_output/Az.dexteroporum_prediction.png" alt="Az.dexteroporum预测图" width="45%" style="margin:10px;"/>
</p>
<div style="margin-top: 30px; text-align: left;">
  <strong>📄 模型报告 PDF</strong><br/><br/>
  📘 <a href="Am.languida Maxent Modeling Report.pdf">Am.languida Maxent Modeling Report</a><br/>
  <em>自动生成的 HTML 报告（通过 RMarkdown 渲染）</em><br/><br/>
  📘 <a href="Az.dexteroporum Maxent Modeling Report.pdf">Az.dexteroporum Maxent Modeling Report</a><br/>
  <em>自动生成的 HTML 报告（通过 RMarkdown 渲染）</em><br/><br/>
  📙 <a href="Maxent model for Am.languida.pdf">Maxent model for Am.languida</a><br/>
  <em>手动构建 Maxent 模型，包含详细参数与图形界面截图</em><br/><br/>
  📙 <a href="Maxent model for Az.dexteroporum.pdf">Maxent model for Az.dexteroporum</a><br/>
  <em>手动构建 Maxent 模型，包含详细参数与图形界面截图</em>
</div>

# Twospecies 物种分布建模项目

---

## 📦 R 包依赖信息

当前 R 版本：4.4.0

以下为本项目涉及的主要 R 包及其版本：

| Package    | Version       |
|------------|---------------|
| corrplot   | 0.95          |
| dplyr      | 1.1.4         |
| ENMeval    | 2.0.4         |
| ggplot2    | 3.5.2         |
| howtext    | Not Installed |
| maxnet     | 0.1.4         |
| rmarkdown  | 2.29          |
| terra      | 1.8.50        |
| tidyr      | 1.3.1         |
| tool       | Not Installed |

---

## 数据声明

> **注意：** 本仓库为示例项目，仅保留脚本、目录结构与模型输出示意图。  
> **原始物种分布点位数据和环境变量数据因涉及使用许可与保密协议，未在仓库中提供。**

如有研究需要，可联系作者获取数据获取授权。

---

## 建模分析流程

### 1. 数据清洗

- **脚本路径：** `scripts/clean-csv.r`
- **输入数据：** `T-occurrences/*.csv`
- **输出数据：** 清洗后的点位（CSV），存于 `T-cleaned_points/`
- ✅ 示例输出：`T-cleaned_points/Az.dexteroporum_cleaned.csv`

### 2. 环境变量处理与筛选

- **预处理脚本：** `scripts/nc-tif-asc.r`
- **相关性分析脚本：** `scripts/cor.r`
- **输入数据：** `T-envir/` 下的 `.nc` 文件和 `.tif`
- **输出数据：**
  - 转换为 `.asc` 或 `.tif`：`T-env_layers_asc/`、`T-env_layers_tif/`
  - 筛选变量文件：`T-cor_analysis/selected_vars.txt`

### 3. Maxent 建模（自动流程）

- **建模脚本：**
  - `T-scripts/Am-maxentmodel.r`：用于 Am.languida
  - `T-scripts/Az-maxentmodel.r`：用于 Az.dexteroporum
- **输出内容：**
  - 模型预测栅格、响应曲线图、Jackknife分析等
  - 存放于 `T-model_output/`、`T-output_Amlanguida/` 与 `T-output_Azdexteroporum/`

### 4. HTML 报告生成（可选）

- **脚本路径：** `T-scripts/report.r`
- **模板文件：** `T-scripts/maxent_report.Rmd`
- **示例输出：**
  - `Am.languida_maxent_report.html`
  - `Az.dexteroporum_maxent_report.html`

### 5. Maxent.jar 手动建模（可选）

- 手动运行 `T-maxent/maxent.jar`，进行参数设置与可视化输出
- 可辅助理解自动流程输出并用于模型对比

---

## 目录结构

```
.
├── 📂 cleaned_points             # 清洗后的物种分布点（CSV 和 Shapefile）
├── 📂 cor_analysis               # 环境变量相关性分析及筛选结果
├── 📂 env_layers_asc             # 环境变量（ASC 栅格格式）
├── 📂 env_layers_tif             # 环境变量（TIF 栅格格式）
├── 📂 envir                      # 原始环境数据（NetCDF、tif等）
├── 💻 maxent                     # Maxent 执行程序及脚本
├── 📊 model_output               # Maxent 建模输出结果（预测栅格、响应曲线等）
├── 📂 occurrences                # 原始物种分布点（CSV）
├── 📂 output_Amlanguida          # Am.languida 物种 Maxent 输出详细文件
├── 📂 output_Azdexteroporum      # Az.dexteroporum 物种 Maxent 输出详细文件
├── 💻 scripts                    # 项目核心 R 脚本
├── 📄 README.md                  # 项目说明文档（本文件）
├── 📄 .gitignore                 # Git 跟踪忽略文件
├── 📄 project_tree.txt           # 项目目录树文本
└── 💻 upload_model_output.sh     # 自动上传脚本示例
```

---

## 快速上手

1. **数据清洗**  
   使用 `scripts/data_cleaning.R` 对 `occurrences/` 中的原始点位数据进行合并、去重和错误剔除。  
   清洗后数据保存在 `cleaned_points/`（CSV 和 Shapefile 格式）。  
   📌 示例路径：`T-cleaned_points/Am.languida_cleaned.csv`

2. **环境变量预处理**  
   使用 `scripts/env_preprocessing.R` 将 `envir/` 中的 NetCDF 和 tif 文件转换为栅格格式，输出至 `env_layers_asc/` 和 `env_layers_tif/`。  
   📌 示例路径：`T-env_layers_asc/po4.asc`, `T-env_layers_tif/po4.tif`

3. **环境变量相关性分析**  
   运行 `scripts/correlation_analysis.R`，对环境变量进行相关性筛选，结果保存在 `cor_analysis/`。  
   📌 示例路径：`T-cor_analysis/selected_vars.txt`

4. **准备 Maxent 输入数据**  
   使用 `scripts/prepare_maxent_input.R`，结合清洗后的点位和筛选后的环境变量，生成 Maxent 所需的样本和背景点文件，存于 `maxent/input/`。  
   📌 示例路径：`maxent/input/species.csv`

5. **运行 Maxent 建模**  
   通过 `scripts/run_maxent.R` 调用 Maxent.jar，自动完成模型训练与预测，结果输出至 `model_output/` 及对应的 `output_Amlanguida/` 和 `output_Azdexteroporum/`。  
   📌 示例路径：`T-output_Amlanguida/Az.dexteroporum_prediction.tif`

---

## Maxent 手动运行指南（macOS / Windows）

除了自动化 R 脚本外，你也可以通过 Maxent 图形界面手动操作模型构建。以下为两种常见操作系统的使用指南：

### 🔧 macOS 上运行 Maxent

1. 打开终端，进入 Maxent 程序目录（本项目为 `maxent/`）：
   ```bash
   cd path/to/project/maxent
   ```

2. 运行 Maxent 图形界面（确保已安装 Java）：
   ```bash
   java -jar maxent.jar
   ```

3. 在弹出的界面中配置以下内容：
   - **Samples file**：物种点 CSV（例如 `T-cleaned_points/Am.languida_cleaned.csv`）
   - **Environmental layers**：选择环境变量文件夹（例如 `T-env_layers_asc/`）
   - **Output directory**：选择结果输出目录（例如 `T-output_Amlanguida/`）
   - 其余参数可默认或根据需求调整

4. 点击 `Run` 开始建模。

---

### 🖥 Windows 上运行 Maxent

1. 双击打开 `maxent/maxent.bat` 或直接在命令行中运行：
   ```cmd
   java -jar maxent.jar
   ```

2. 同样在图形界面中设置输入文件和输出路径。

3. 如需批量建模或自动执行，也可以写 `.bat` 脚本，结合参数化操作运行多个物种模型。

---

> 注意：Projection layers 可选，仅在需要对模型进行转移投影（如预测未来气候或其他区域）时配置。


---

## 贡献指南

感谢您对本项目的关注与支持！  
欢迎提交 issue 和 pull request，帮助我们完善项目。  

- 请确保代码风格统一，注释清晰  
- 提交前请测试相关功能，确保无误  
- 对于数据和脚本的修改，请在 README 或注释中详细说明  

---

## 致谢

感谢AI，感谢 Maxent 软件提供的强大建模支持。  
项目参考了多篇物种分布建模领域的经典文献与开源资源。

---

## License

本项目遵循 [MIT License](https://opensource.org/licenses/MIT) 许可协议，欢迎自由使用和修改，但请保留原作者信息。
