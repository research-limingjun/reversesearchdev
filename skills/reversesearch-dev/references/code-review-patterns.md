# 代码审核常见问题模式

## 1. 共享航班判断逻辑统一到公共基类

**审核问题**：共享航班判断逻辑未统一到基类，各处实现不一致。

> ⚠️ **审核要点**：审核要求逻辑必须放到 **公共基类（BaseService）** 作为 `protected` 方法，不能是子类中的 `private` 方法。第一次修复放在 private 方法中被打回。

**背景**：共享航班（codeshare）的市场航班号和实际承运航班号不同。匹配航段时需要用实际承运航班号，否则相同运营航班的共享航班会匹配失败。

**字段映射**：

| VO 类型 | 共享标识字段 | 运营航班号字段 | 航司编码字段 | 运营航司编码字段 |
|---------|-------------|---------------|-------------|----------------|
| `SegmentDTO` (changecore) | 需计算 | `shareFlightNo` | `carrierCode` | `actualCarrierCode` |
| `FlightUniformSegmentVO` (reversebase) | `shared` (Boolean) | `opFlightNo` | `carrierCode` | `opCarrierCode` |
| `RepeatSegmentPriceVO` (reversesearch) | `share` (Boolean) | `shareFlightNo` | - | - |

**判断共享航班的统一逻辑**：

```java
// SegmentDTO: carrierCode != actualCarrierCode 即为共享
boolean shared = segment.getCarrierCode() != null 
    && !segment.getCarrierCode().equals(segment.getActualCarrierCode());

// FlightUniformSegmentVO: 直接用 shared 字段
boolean shared = Boolean.TRUE.equals(segment.getShared());

// RepeatSegmentPriceVO: 直接用 share 字段
boolean shared = Boolean.TRUE.equals(segment.getShare());
```

**正确做法：在 BaseService 中定义 protected 方法**：

```java
// BaseService.java 中新增（需要 import StringUtils, SegmentDTO, FlightUniformSegmentVO, RepeatSegmentPriceVO）
protected String getEffectiveFlightNo(SegmentDTO segment) {
    boolean shared = segment.getCarrierCode() != null 
        && !segment.getCarrierCode().equals(segment.getActualCarrierCode());
    if (shared && StringUtils.isNotEmpty(segment.getShareFlightNo())) {
        return segment.getShareFlightNo();
    }
    return segment.getFlightNo();
}

protected String getEffectiveFlightNo(FlightUniformSegmentVO segment) {
    if (Boolean.TRUE.equals(segment.getShared()) && StringUtils.isNotEmpty(segment.getOpFlightNo())) {
        return segment.getOpFlightNo();
    }
    return segment.getFlightNo();
}

protected String getEffectiveFlightNo(RepeatSegmentPriceVO segment) {
    if (Boolean.TRUE.equals(segment.getShare()) && StringUtils.isNotEmpty(segment.getShareFlightNo())) {
        return segment.getShareFlightNo();
    }
    return segment.getFlightNo();
}
```

**错误做法（被打回）**：在子类 `RepeatPriceChangeServiceImpl` 中定义 private 方法 — 审核要求"统一到基类"。

**参考**：`BaseFlightUnitConverter` 第 235-236 行的共享航班判断逻辑：
```java
// 是否共享航班的判断放到这个基类中处理 就判断航司编码和共享航司编码是否相等 不相等代表true共享
flightSegmentVO.setShared(!StringUtils.equals(flightSegmentVO.getCarrierCode(), flightSegmentVO.getOpCarrierCode()));
```

## 2. 枚举值过滤 — 排除默认值

**审核问题**：枚举值过滤存在默认值误杀风险。

> ⚠️ **审核要点**：仅检查 null 不够，还必须排除**默认值 0**。第一次修复只加了 null 检查被打回。

**枚举默认值分析**：

| 枚举类 | code=0 对应值 | 含义 | 是否应过滤 |
|--------|-------------|------|----------|
| `ChangeStateEnum` | `WAIT_HANDLE(0)` | 待处理 | ✅ 应过滤（未初始化/默认值） |
| `ChangeSubTypeEnum` | 无（最小值是 1） | 无对应枚举 | ✅ 应过滤（未初始化/默认值） |

**风险点**：

1. **Integer 自动拆箱 NPE**：`getEnumByCode(int code)` 参数是 `int`，传入 `Integer null` 会 NPE
2. **默认值 0 误杀**：`cancelChangeState=0` 映射到 `WAIT_HANDLE`，不等于 `USER_CONFIRM`，会被过滤掉（但 0 可能是未初始化的默认值，不应作为有效过滤条件）
3. **枚举查找返回 null**：`getEnumByCode()` 找不到匹配值时返回 `null`

**反面案例**：
```java
// ❌ cancelChangeState 为 null 时 NPE
if (ChangeStateEnum.USER_CONFIRM != ChangeStateEnum.getEnumByCode(extDTO.getCancelChangeState())) { ... }

// ❌ 只检查 null，不检查默认值 0
if (extDTO.getCancelChangeState() == null
    || ChangeStateEnum.USER_CONFIRM != ChangeStateEnum.getEnumByCode(extDTO.getCancelChangeState())) { ... }
```

**正确写法**：
```java
// ✅ 排除 null 和默认值 0
if (extDTO.getCancelChangeState() == null || extDTO.getCancelChangeState() == 0
    || ChangeStateEnum.USER_CONFIRM != ChangeStateEnum.getEnumByCode(extDTO.getCancelChangeState())) {
    LoggerUtils.info(LOGGER, "{}取消状态为空或为默认值或非待用户确认状态,不能用作报价, cancelChangeState={}", 
        cancelChangeOrder.getChangeSerialNo(), extDTO.getCancelChangeState());
    continue;
}

// ✅ 先获取 code，排除 null 和 0，再查枚举
Integer changeSubTypeCode = cancelChangeOrder.getChangeSubType();
ChangeSubTypeEnum changeSubType = changeSubTypeCode == null ? null : ChangeSubTypeEnum.getEnumByCode(changeSubTypeCode);
if (changeSubTypeCode == null || changeSubTypeCode == 0 || changeSubType == ChangeSubTypeEnum.DELAY_CHANGE) {
    LoggerUtils.info(LOGGER, "{}改签子类型为空或为默认值或航变改签,不能用作报价, changeSubType={}", 
        cancelChangeOrder.getChangeSerialNo(), cancelChangeOrder.getChangeSubType());
    continue;
}
```

**通用规则**：
1. 对 `Integer` 类型的枚举 code，调用 `getEnumByCode()` 前必须先做 null 检查
2. 对可能有默认值 0 的字段，增加 `== 0` 检查
3. 对 `getEnumByCode()` 的返回值，必须先检查 null 再做枚举比较
4. 日志应包含实际值（如 `cancelChangeState={}`），便于线上排查

## 3. mailState 过滤优化（2026-06-09 新增）

**背景**：`mailState` 字段有多个状态值，不能简单地 `!= null` 就过滤。

**正确做法**：仅过滤已邮寄状态（`MAILED_STATE = 2`），`NO_MAIL`/`WAIT_MAIL` 不影响报价。

```java
private static final int MAILED_STATE = 2;

// ✅ 仅过滤已邮寄
if (cancelChangeOrder.getMailState() != null && cancelChangeOrder.getMailState() == MAILED_STATE) {
    LoggerUtils.info(LOGGER, "{}已邮寄发票,不能用作报价, mailState={}", 
        cancelChangeOrder.getChangeSerialNo(), cancelChangeOrder.getMailState());
    continue;
}
```
