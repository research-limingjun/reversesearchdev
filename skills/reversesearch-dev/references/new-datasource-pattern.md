# 新增数据源实现模式

## 概述
reversesearch 项目采用 Engine Source 架构，每个数据源由三层组成：
```
Query Service 层 → Engine Source 层 → Converter 层 → Integration Client 层
```

## 新增数据源步骤

### 1. 确定复用哪个 Client
- **IBE Client** (`IbeClient`): 黑屏报价，并发查询，最复杂
- **OneT Client** (`OneTClient`): ATPCO，航班+价格一体返回
- **Reshop Client** (`ReshopClient`): 差额报价，币种转换
- **Crawler Client** (`CrawlerClient`): HTTP 接口，LCC 补充

### 2. 创建 EngineSource
**路径**: `app/biz/src/main/java/.../enginesource/voluntarychange/XxxFlightEngineSource.java`

**关键点**:
- 继承 `BaseService`
- 注入复用的 Client（如 `IbeClient`）
- 注入对应的 Converter（如 `XxxFlightUnitConverter`）
- 使用 `DictConstant` 中的超时常量
- 实现 `queryFlightPrice()` 方法

**参考**: `TwFlightEngineSource.java`（简化版）、`IbeFlightEngineSource.java`（完整版）

### 3. 创建 Converter
**路径**: `app/biz/src/main/java/.../converter/voluntarychange/XxxFlightUnitConverter.java`

**关键点**:
- 继承 `BaseFlightUnitConverter`
- 使用 `@Service("xxxFlightUnitConverter")` 注解
- 实现 `converter()` 方法
- 处理乘客类型转换（STU → ADT）
- 组装报价信息和行李额

**两种实现方式**:

#### 方式 A：委托模式（推荐，当复用现有 Client 时）
如果新数据源复用现有 Client（如 IBE），响应格式一致，直接委托现有 Converter：
```java
@Service("twFlightUnitConverter")
@Slf4j
public class TwFlightUnitConverter extends BaseFlightUnitConverter {
    @Resource
    private IbeFlightUnitConverter ibeFlightUnitConverter;

    public FlightUnitPriceVO converter(PriceValidateResponse responseDTO, PriceValidateRequest requestDTO, 
            IbePriceContext ibePriceContext, FlightUnitVO flightUnitVO, FlightUnitPriceVO priceInfo) 
            throws SearchBizException, IntegrationException {
        // 直接委托，避免复制私有验证方法
        return ibeFlightUnitConverter.converter(responseDTO, requestDTO, ibePriceContext, flightUnitVO, priceInfo);
    }
}
```
**优点**: 避免复制 IbeFlightUnitConverter 中的私有验证方法（validateBrandCode、validatePriceType、validateTicketPrice、validateFareBasis、validateBaggage）

#### 方式 B：独立实现（当响应格式不同时）
如果新数据源使用不同的响应格式，需要独立实现全部转换逻辑。

**参考**: `TwFlightUnitConverter.java`（委托模式）、`IbeFlightUnitConverter.java`（完整实现）

### 4. 添加超时常量（如需要）
**文件**: `app/integration/src/main/java/.../config/DictConstant.java`

**格式**:
```java
/** XXX 航班查询超时时间 单位 毫秒 */
public static final String XXX_FLIGHT_QUERY_TIME_OUT_MILLISECOND = "XXX_FLIGHT_QUERY_TIME_OUT_MILLISECOND";
```

### 5. 创建事件类（如需要）
**路径**: `app/biz/src/main/java/.../event/reversereport/XxxSearchEvent.java`

## 枚举值复用

当新增数据源时，如果没有对应的枚举值，应复用现有枚举：

- `AutoPriceFlagEnum`: 使用 `IBE_AUTO`（在 `changecore` 项目中定义）
- `ChangeAutoPriceMethodEnum`: 使用 `IBE_AUTO`（在 `reversebase` 项目中定义）

> **注意**: 这些枚举在外部 JAR 包中定义，无法直接修改。如需新增枚举值，需要修改对应的外部项目并发布新版本。

### 枚举值验证方法
在使用枚举值前，必须验证其存在于当前依赖版本中：
```bash
# 检查 AutoPriceFlagEnum 的所有值
cd /tmp && jar xf /Users/apple/.m2/repository/com/ly/flight/intl/changecore-model/X.X.X.RELEASE/changecore-model-X.X.X.RELEASE.jar \
  com/ly/flight/intl/changecore/model/enums/check/AutoPriceFlagEnum.class && \
  javap com/ly/flight/intl/changecore/model/enums/check/AutoPriceFlagEnum.class | grep "static"

# 检查 ChangeAutoPriceMethodEnum 的所有值
cd /tmp && jar xf /Users/apple/.m2/repository/com/ly/flight/intl/reversebase-common/X.X.X.RELEASE/reversebase-common-X.X.X.RELEASE.jar \
  com/ly/flight/intl/reversebase/common/enums/flightunitquery/ChangeAutoPriceMethodEnum.class && \
  javap com/ly/flight/intl/reversebase/common/enums/flightunitquery/ChangeAutoPriceMethodEnum.class | grep "static"
```

**已知存在的枚举值**（截至 2026-06-03）:
- AutoPriceFlagEnum: DEFAULT, ETERM_AUTO, GW_AUTO, REPEAT_AUTO, ONE_T_AUTO, SPEED_CHANGE_AUTO, LOW_COST, RM, IBE_AUTO, RESHOP_AUTO, CRAWLER_AUTO
- ChangeAutoPriceMethodEnum: ONLY_FLIGHT_WITHOUT_PRICE, ETERM_AUTO, SPEED_CHANGE, DELAY_CHANGE, GW_AUTO, REPEAT_AUTO, ONE_T_AUTO, IBE_AUTO, RESHOP_AUTO, CRAWLER_AUTO

## TW 数据源实现示例（2026-06-09 更新）

### 实现概况
- **独立 Client**: TwClient/TwClientImpl（HTTP 接口，独立于 IBE）
- **新增文件**: 9 个
  - Integration 层：TwClient, TwClientImpl, TwSearchRequestDTO, TwSearchResponseDTO
  - Biz 层：TwFlightEngineSource, TwFlightUnitConverter, TwQueryChangeFlightFilter, TwFlightWithPriceQueryServiceImpl
  - Event 层：TwSearchEvent
- **依赖修改**: 2 个
  - reversebase: 新增 TwPriceExtVO（报价扩展字段）
  - changecore: 扩展 AutoPriceFlagEnum.TW_AUTO(11)
- **编译顺序**: reversebase → changecore → reversesearch（必须按此顺序！）

### 关键决策
1. **独立 HTTP Client**: TW 使用独立的 HTTP 接口（非 IBE 协议），需要 TwClient/TwClientImpl
2. **独立 Converter**: TwFlightUnitConverter 独立实现，不委托 IbeFlightUnitConverter（响应格式不同）
3. **独立 Filter**: TwQueryChangeFlightFilter 独立实现（与 CrawlerQueryChangeFlightFilter 结构相同）
4. **新增枚举值**: AutoPriceFlagEnum.TW_AUTO(11)（需修改 changecore 项目）

### 代码结构
```
Integration 层:
├── TwClient.java                    # 客户端接口
├── TwClientImpl.java                # HTTP 客户端实现
├── TwSearchRequestDTO.java          # 请求 DTO
└── TwSearchResponseDTO.java         # 响应 DTO

Biz 层:
├── TwFlightEngineSource.java        # 数据源（调用 Client + 转换结果）
├── TwFlightUnitConverter.java       # 结果转换器（响应→FlightUnitVO）
├── TwQueryChangeFlightFilter.java   # 航班过滤器
└── TwFlightWithPriceQueryServiceImpl.java  # 查询服务入口（isSupport + query）

Event 层:
└── TwSearchEvent.java               # 搜索埋点事件
```

### 请求/响应格式
- **请求**: TwSearchRequestDTO（独立格式，包含 airline、passengers、oldSegments、newSegments）
- **响应**: TwSearchResponseDTO（独立格式，包含 flightUnits、priceinfo）
- **事件**: TwSearchEvent

### 跨模块依赖
- **reversebase**: TwPriceExtVO（extends DelayPriceExtVO）
- **changecore**: AutoPriceFlagEnum.TW_AUTO(11)

### 编译依赖顺序
```bash
# 1. reversebase（新增 TwPriceExtVO）
cd /Users/apple/work/tc-flight-int-reversebase
find . -name "pom.xml" -exec sed -i '' 's/旧版本/新版本/g' {} \;
mvn install -DskipTests

# 2. changecore（新增 AutoPriceFlagEnum.TW_AUTO）
cd /Users/apple/work/tc-flight-int-changecore
mvn install -pl app/model -DskipTests

# 3. reversesearch
cd /Users/apple/work/tc-flight-int-reversesearch
mvn compile -pl app/integration,app/biz -am -DskipTests
```

### 常见错误
- ❌ 直接使用不存在的枚举值（如 AutoPriceFlagEnum.TW_AUTO）→ 编译错误
- ✅ 正确做法：先在 changecore 中添加枚举值，再 `mvn install`
- ❌ 只更新 reversebase 父 pom 版本号 → 子模块版本不一致
- ✅ 正确做法：用 `find . -name "pom.xml" -exec sed` 更新所有子模块
- ❌ 调用不存在的方法（如 getChangeFeeByChangeRule）→ 编译错误
- ✅ 正确做法：先 grep 检查方法签名，使用 getChangeFeeByChangeRuleOrCrawlerFallback

### 实现概况
- **复用 Client**: IbeClient（黑屏报价接口）— 复用 IBE 协议
- **新增文件**: 3 个（TwFlightEngineSource、TwFlightUnitConverter、TwSearchEvent）
- **修改文件**: 1 个（DictConstant 新增 TW 超时常量）
- **工时**: 约 1 天

### 关键决策
1. **复用 IbeClient**: TW 使用与 IBE 相同的黑屏报价接口（`ibeClient.ibeSearchPrice()`），复用现有协议
2. **委托 Converter**: TwFlightUnitConverter 委托 IbeFlightUnitConverter 处理核心转换逻辑，避免复制私有验证方法
3. **独立事件类**: 新增 TwSearchEvent（虽然当前使用 AutoPriceFlagEnum.IBE_AUTO，但事件类独立便于未来区分）
4. **复用枚举值**: 使用 AutoPriceFlagEnum.IBE_AUTO 和 ChangeAutoPriceMethodEnum.IBE_AUTO（TW_AUTO 不存在）

### 代码结构
```
TwFlightEngineSource.java
├── queryFlightPrice()          // 主入口，并发查询
├── buildFlightFutureHolders()  // 构建 Future 列表
├── doTwSearch()                // 执行单次查询
├── buildTwRequestParams()      // 组装 PriceValidateRequest
└── getOriginDestinations()     // 获取 OD 信息

TwFlightUnitConverter.java
└── converter()                 // 委托给 IbeFlightUnitConverter

TwSearchEvent.java
└── 构造函数                    // 搜索埋点事件
```

### 请求/响应格式
- **请求**: PriceValidateRequest（与 IBE 完全一致）
- **响应**: PriceValidateResponse（与 IBE 完全一致）
- **事件**: TwSearchEvent

### 常见错误
- ❌ 直接使用不存在的枚举值（如 AutoPriceFlagEnum.TW_AUTO）→ 编译错误
- ✅ 正确做法：先用 `javap` 检查枚举值是否存在，不存在则复用 IBE_AUTO
- ❌ 复制 IbeFlightUnitConverter 的私有验证方法到新 Converter → 代码重复，维护困难
- ✅ 正确做法：委托 IbeFlightUnitConverter 处理（见方式 A）
