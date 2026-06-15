# changecore-facade DTO 结构（model.psi vs response.query）

## 关键发现（2026-06-08 TASK-009 验证）

**`model.psi.ChangeInfoDTO` 和 `response.query.ChangeInfoDTO` 是两个不同的类！**

| DTO 类 | 包路径 | 用途 | 有 `invoice`? | 有 `mailState`? |
|--------|--------|------|--------------|----------------|
| `ChangeInfoDTO` | `model.psi` | 改签单详情（API 返回） | ❌ 无 | ✅ 有 |
| `ChangeInfoDTO` | `response.query` | 列表查询轻量 DTO | ✅ 有 | ❌ 无 |
| `ChangeInvoiceDTO` | `model.psi` | 发票详情 | N/A | ✅ 有 |

## API 返回类型

| API 方法 | 返回类型 | 包含的 ChangeInfoDTO |
|----------|----------|---------------------|
| `queryChangeDetailsByOrderSerialNo` | `ChangeOrderResponseDTO` | `model.psi.ChangeInfoDTO` |
| `QueryChangeListResponseDTO` | 列表 DTO | `response.query.ChangeInfoDTO` |

## `model.psi.ChangeInfoDTO` 关键字段

```
com.ly.flight.intl.changecore.facade.model.psi.ChangeInfoDTO
├── changeState (Integer)
├── orderSerialNo (String)
├── changeType (Integer)
├── changeSubType (Integer)
├── mailState (Integer)          ← 邮寄状态（可用于判断是否有邮寄发票）
├── extDTO (ChangeExtDTO)
├── order (OrderDTO)
├── psis (List<PSIDTO>)
└── ... (其他业务字段)
```

**注意**：此类没有 `invoice` 字段！只有 `mailState`。

## `response.query.ChangeInfoDTO` 关键字段

```
com.ly.flight.intl.changecore.facade.response.query.ChangeInfoDTO
├── resource (String)
├── merchantId (String)
├── orderSerialNo (String)
├── ruleType (Integer)
├── changeTime (Date)
└── invoice (ChangeInvoiceDTO)   ← 发票详情（包含 invoiceOption, mailState, contact 等）
```

## `ChangeInvoiceDTO` 字段

```
com.ly.flight.intl.changecore.facade.model.psi.ChangeInvoiceDTO
├── invoiceOption (Integer)      ← 邮寄方式(1：纸质凭证 2：电子凭证)
├── mailState (Integer)          ← 邮寄状态
├── contact (String)             ← 联系人
├── contactMobile (String)       ← 联系电话
├── provinceName / provinceId    ← 省份
├── cityName / cityId            ← 城市
├── districtName / districtId    ← 区
├── address (String)             ← 详细地址
├── email (String)               ← 邮箱地址
├── supplier (Integer)           ← 供应商(1-顺丰，2-EMS，3-天天，4-汇通)
├── invoiceTitle (String)        ← 发票抬头
└── customerIdentifier (String)  ← 纳税人识别号
```

## 邮寄发票判断逻辑（正确方式）

由于 reversesearch 使用 `model.psi.ChangeInfoDTO`（来自 `queryChangeDetailsByOrderSerialNo` API），
而该 DTO 没有 `invoice` 字段，必须使用 `mailState` 判断：

```java
// ✅ 正确：使用 mailState
private boolean hasMailingInvoice(ChangeInfoDTO changeInfoDTO) {
    return changeInfoDTO.getMailState() != null;
}

// ❌ 错误：model.psi.ChangeInfoDTO 没有 getInvoice() 方法，编译失败
private boolean hasMailingInvoice(ChangeInfoDTO changeInfoDTO) {
    return changeInfoDTO.getInvoice() != null;
}
```

## 版本变更记录

| 版本 | model.psi.ChangeInfoDTO | response.query.ChangeInfoDTO |
|------|------------------------|------------------------------|
| 1.6.4.65.RELEASE | 有 `mailState`，无 `invoice` | 无 `invoice` |
| 1.6.4.66-SNAPSHOT | 有 `mailState`，无 `invoice` | 有 `invoice`（新增） |

**结论**：TASK-008 在 `response.query.ChangeInfoDTO` 上新增了 `invoice` 字段，但 `model.psi.ChangeInfoDTO` 未变。
reversesearch 需要使用 `mailState` 字段进行判断。
