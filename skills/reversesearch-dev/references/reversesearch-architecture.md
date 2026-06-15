# reversesearch 项目架构参考

## 项目结构
```
app/
├── integration/          # 集成层（RPC 调用）
│   └── src/main/java/com/ly/flight/intl/reversesearch/integration/client/
│       ├── changecore/ChangeCoreClientImpl.java   # 改签核心客户端
│       ├── auxiliary/                              # 辅营核心客户端（待创建）
│       ├── reshop/ReshopClientImpl.java           # 重购客户端
│       ├── crawler/CrawlerClientImpl.java         # 爬虫客户端
│       ├── onet/OneTClientImpl.java               # 1T 客户端
│       ├── refundcore/RefundQueryClientImpl.java  # 退订查询客户端
│       └── BaseClient.java                        # 客户端基类
├── biz/                  # 业务逻辑层
│   └── src/main/java/com/ly/flight/intl/reversesearch/biz/manager/support/
│       ├── FlightUnitQueryValidateServiceImpl.java  # 航班查询前置校验
│       └── FlightUnitSupplementServiceImpl.java     # 航班补充服务
└── integration/src/main/resources/META-INF/spring/
    └── reversesearch-integration-rpc-beans-xml.xml  # RPC Bean 配置
```

## RPC 配置文件位置
- `app/integration/src/main/resources/META-INF/spring/reversesearch-integration-rpc-beans-xml.xml`

## 现有 RPC Bean 配置示例
```xml
<!-- 辅营核心服务（GoodsCoreFacade） -->
<sof:reference id="auxiliaryCoreFacade"
               serviceName="goodscore"
               gsName="${integration.reverseauxiliary.gsName}"
               interface="com.ly.flight.intl.reverseauxiliary.facade.GoodsCoreFacade"
               version="${integration.reverseauxiliary.version}"
               timeout="30000"
               retries="2" serializer="FASTJSON">
    <sof:method name="reverseGoodsQuery" paramType="bodyParam" timeout="10000"/>
</sof:reference>

<!-- 改签核心服务 -->
<sof:reference id="changeCoreFacade" serviceName="changecore"
               gsName="${integration.changecore.gsName}"
               interface="com.ly.flight.intl.changecore.facade.ChangeCoreFacade"
               version="${integration.changecore.version}"
               timeout="30000"
               retries="0"
               serializer="FASTJSON">
    <sof:method name="changecheck" retries="0" paramType="bodyParam" timeout="10000"/>
</sof:reference>
```

## 客户端实现模式（以 ChangeCoreClientImpl 为例）
```java
@Service
public class ChangeCoreClientImpl {
    @Resource
    private ChangeCoreFacade changeCoreFacade;

    @IntegrationLogCfg(interfaceName = "xxx", successMethod = "isSuccess", 
                       errorCodeMethod = "getErrorCode", errorMessageMethod = "getErrorMessage")
    public XxxResponseDTO xxxMethod(XxxRequestDTO requestDTO) throws IntegrationException {
        // 1. 构建请求
        // 2. 调用 RPC
        // 3. 返回响应
    }
}
```

## 校验服务集成点
- **文件**: `FlightUnitQueryValidateServiceImpl.java`
- **方法**: `validate(FlightUnitsQueryContext flightUnitsQueryContext)`
- **调用位置**: 在方法开头添加前置校验
- **异常处理**: 使用 `ValidateErrorException` 抛出业务异常
- **降级策略**: RPC 异常时记录日志但不阻断查询

## 错误工厂
- **位置**: `SEARCH_BIZ_ERROR_FACTORY`（BaseService 中定义）
- **使用方式**: `throw new ValidateErrorException(SEARCH_BIZ_ERROR_FACTORY.xxxErrorMsg(...))`
