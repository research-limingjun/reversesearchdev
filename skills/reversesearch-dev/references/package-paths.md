# reversesearch 常用类包路径参考

> 设计文档中的包路径可能不准确，以下为实际验证的路径。

## 乘客相关

| 类名 | 实际包路径 |
|------|-----------|
| `PassengerTypeEnum` | `com.ly.flight.intl.reversebase.common.b2corder.enums` |
| `PassengerInfoVO` | `com.ly.flight.intl.reversebase.common.b2corder.vo.opsi` |
| `OrderInfoVO` | `com.ly.flight.intl.reversebase.common.b2corder.vo.opsi` |
| `SegmentInfoVO` | `com.ly.flight.intl.reversebase.common.b2corder.vo.opsi` |
| `SegmentTypeEnum` | `com.ly.flight.intl.reversebase.common.b2corder.enums` |

## 工具类

| 类名 | 实际包路径 |
|------|-----------|
| `OrderInfoUtils` | `com.ly.flight.intl.reversesearch.common.util` |

## 异常类

| 类名 | 实际包路径 |
|------|-----------|
| `ValidateErrorException` | `com.ly.flight.intl.reversebase.common.exception` |
| `ValidateWarnException` | `com.ly.flight.intl.reversebase.common.exception` |
| `IntegrationException` | `com.ly.flight.intl.reversebase.common.exception` |

## 注意事项

- `PassengerTypeEnum.INF` 是婴儿类型
- `OrderInfoUtils.getPassengers(orderInfoVO)` 获取乘客列表（已过滤已退票乘客）
- `BaseService` 使用 `logger` 而非 `log` 记录日志
