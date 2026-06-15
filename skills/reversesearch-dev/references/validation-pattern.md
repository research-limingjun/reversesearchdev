# 校验逻辑实现模式

## 婴儿旅客校验示例（TASK-002）

### 场景
在改签查询前校验订单是否包含婴儿旅客（INF），如包含则拦截查询。

### 实现步骤

#### 1. 新增错误枚举
文件：`SearchFailReasonEnum.java`
```java
INFANT_NOT_SUPPORTED("LY0513000050", "订单包含婴儿 不支持查询", "婴儿限制", "业务异常"),
```
- 错误码格式：`LY0513XXXXX`，从现有最大编号递增
- 构造函数参数：(code, thirdType, secondType, firstType)

#### 2. 新增错误工厂方法
文件：`SearchBizErrorFactory.java`
```java
public LYError infantNotSupportedErrorMsg() {
    return createError(SearchFailReasonEnum.INFANT_NOT_SUPPORTED.getCode());
}
```
- 无参数的错误直接调用 `createError(code)`
- 有参数的错误调用 `createError(code, arg1, arg2, ...)`

#### 3. 新增错误消息
文件：`reverse-search-biz-error-messages.properties`
```
LY0513000050=订单包含婴儿 不支持查询  (Unicode escaped: \u8BA2\u5355\u5305\u542B\u5A74\u513F \u4E0D\u652F\u6301\u67E5\u8BE2)
```
- 使用 Unicode 转义格式
- 使用 `printf >>` 追加，不用 patch 工具（Pitfall #25）

#### 4. 在 validate() 方法开头插入校验
文件：`FlightUnitQueryValidateServiceImpl.java`
```java
// 0.校验订单是否包含婴儿旅客，包含婴儿则拦截查询
List<PassengerInfoVO> requestPassengerInfos = flightUnitsQueryContext.getRequestPassengerInfos();
if (requestPassengerInfos != null && requestPassengerInfos.stream()
        .anyMatch(p -> PassengerTypeEnum.INF == p.getPassengerType())) {
    throw new ValidateErrorException(SEARCH_BIZ_ERROR_FACTORY.infantNotSupportedErrorMsg());
}
```
- 校验放在方法最开头，避免不必要的 RPC 调用
- 需要新增 import：`PassengerTypeEnum`、`PassengerInfoVO`
- 注意避免重复变量声明（Pitfall #35）

#### 5. 编写单元测试
文件：`FlightUnitQueryValidateServiceImplTest.java`

**包含婴儿 - 应抛异常**：
```java
@Test
@DisplayName("婴儿旅客校验 - 包含婴儿应抛出异常")
void testValidateInfantPassenger() {
    // 构造包含 INF 类型的乘客列表
    List<PassengerInfoVO> passengerInfos = new ArrayList<>();
    PassengerInfoVO adultPassenger = new PassengerInfoVO();
    adultPassenger.setPassengerType(PassengerTypeEnum.ADT);
    passengerInfos.add(adultPassenger);
    PassengerInfoVO infantPassenger = new PassengerInfoVO();
    infantPassenger.setPassengerType(PassengerTypeEnum.INF);
    passengerInfos.add(infantPassenger);
    ReflectionTestUtils.setField(ctx, "requestPassengerInfos", passengerInfos);
    
    Assertions.assertThrows(ValidateErrorException.class, () -> service.validate(ctx));
}
```

**不含婴儿 - 应正常放行**：
```java
@Test
@DisplayName("婴儿旅客校验 - 不含婴儿应正常放行")
void testValidateNoInfantPassenger() throws Exception {
    // 构造仅含 ADT 类型的乘客列表
    List<PassengerInfoVO> passengerInfos = new ArrayList<>();
    PassengerInfoVO adultPassenger = new PassengerInfoVO();
    adultPassenger.setPassengerType(PassengerTypeEnum.ADT);
    passengerInfos.add(adultPassenger);
    ReflectionTestUtils.setField(ctx, "requestPassengerInfos", passengerInfos);
    
    // 正常放行，返回校验结果
    List<PassengerSegmentCheckDTO> result = service.validate(ctx);
    Assertions.assertEquals(1, result.size());
}
```

### 相关 Pitfall
- Pitfall #14: BaseService 使用 `logger` 而非 `log`
- Pitfall #15: ValidateErrorException 是受检异常
- Pitfall #25: Unicode 转义的 properties 文件不能用 patch 工具编辑
- Pitfall #35: 在方法开头插入代码时避免重复变量声明

### 测试验证命令
```bash
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_191.jdk/Contents/Home && \
/Users/apple/workspace/soft/apache-maven-3.6.3/bin/mvn test \
  -Dtest=FlightUnitQueryValidateServiceImplTest \
  -Dsurefire.failIfNoSpecifiedTests=false \
  -Dmaven.compiler.failOnError=false \
  -pl app/biz -am
```
