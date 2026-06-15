# changecore 邮寄发票领域知识

## 数据模型层次（2026-06-08 更新）

| 层次 | 类 | 说明 |
|------|-----|------|
| Biz VO | `ChangeInvoiceVO` | 完整的邮寄发票信息（biz层内部使用） |
| Biz VO | `ChangeVO.invoice` | ChangeVO 持有 ChangeInvoiceVO 引用 |
| Facade DTO | `model.psi.ChangeInfoDTO` | 改签单详情（API 返回）：**只有 `mailState`，没有 `invoice`** |
| Facade DTO | `response.query.ChangeInfoDTO` | 列表查询轻量 DTO：**有 `invoice`（ChangeInvoiceDTO）** |
| Facade DTO | `ChangeExtDTO` | 无发票字段 |
| Facade DTO | `ChangeInvoiceDTO` | 发票详情DTO（同 ChangeInvoiceVO 字段） |

⚠️ 两个 `ChangeInfoDTO` 是不同的类！详见 `references/changecore-facade-dto-structure.md`

## ChangeInvoiceVO 字段

包路径: `com.ly.flight.intl.changecore.biz.model.vo.common.ChangeInvoiceVO`

| 字段 | 类型 | 说明 |
|------|------|------|
| `invoiceOption` | `Integer` | 邮寄方式(1：纸质凭证 2：电子凭证) |
| `mailState` | `MailStateEnum` | 邮寄状态 |
| `contact` | `String` | 联系人 |
| `contactMobile` | `String` | 联系电话 |
| `provinceName` / `provinceId` | `String` / `Integer` | 省份 |
| `cityName` / `cityId` | `String` / `Integer` | 城市 |
| `districtName` / `districtId` | `String` / `Integer` | 区 |
| `address` | `String` | 详细地址 |
| `email` | `String` | 邮箱地址 |
| `supplier` | `SupplierEnum` | 供应商(1-顺丰，2-EMS，3-天天，4-汇通) |
| `invoiceTitle` | `String` | 发票抬头 |
| `customerIdentifier` | `String` | 纳税人识别号 |
| `creator` | `String` | 创建人 |

## 组装流程

```
ChangeInfoAssembly.assemble()
  → changeInvoiceAssembly.assembly(context)  // 组装邮寄发票信息
  → changeVO.setInvoice(...)                 // 设置到 ChangeVO
```

## Facade 层状态

### ⚠️ 重要：model.psi.ChangeInfoDTO 没有 invoice 字段（2026-06-08 验证）

**`model.psi.ChangeInfoDTO`（API 返回的改签单详情）只有 `mailState`，没有 `invoice`！**

- `invoice` 字段在 `response.query.ChangeInfoDTO`（列表查询轻量 DTO）上
- API `queryChangeDetailsByOrderSerialNo` 返回 `model.psi.ChangeInfoDTO`
- 因此 `changeInfoDTO.getInvoice()` 会编译失败

**正确的判断逻辑**（TASK-002 最终实现）：
```java
private static final int MAILED_STATE = 2;

// 仅过滤已邮寄状态，NO_MAIL/WAIT_MAIL 不影响报价
if (cancelChangeOrder.getMailState() != null && cancelChangeOrder.getMailState() == MAILED_STATE) {
    LoggerUtils.info(LOGGER, "{}已邮寄发票,不能用作报价, mailState={}", ...);
    continue;
}
```

- `mailState` 为 null → 无邮寄发票 → 不过滤
- `mailState` 为 `NO_MAIL` 或 `WAIT_MAIL` → 未实际邮寄 → 不过滤
- `mailState` 为 `MAILED` (code=2) → 已邮寄 → 过滤该改签单

> ⚠️ 不能简单用 `mailState != null` 过滤，因为 `NO_MAIL`/`WAIT_MAIL` 状态不影响报价。

⚠️ 详见 `references/changecore-facade-dto-structure.md` 了解两个 ChangeInfoDTO 的区别

### MailStateEnum 枚举值

- `NO_MAIL` — 无邮寄
- `WAIT_MAIL` — 待邮寄
- `MAILED` — 已邮寄

包路径: `com.ly.flight.intl.reversebase.common.enums.postinvoice.MailStateEnum`

## 相关枚举

- `MailStateEnum` — 邮寄状态枚举（包: `com.ly.flight.intl.reversebase.common.enums.postinvoice`）
- `SupplierEnum` — 快递供应商枚举（同包）
