# 单元测试私有方法模式（JUnit 5 + Reflection）

## 适用场景

测试 `private` 方法（如 `matchChangeOrder`），无法直接调用。

## 完整模板

```java
package com.ly.flight.intl.reversesearch.biz.service.flightprice.repeat;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.*;

@ExtendWith(MockitoExtension.class)
public class RepeatPriceChangeServiceImplTest {

    @InjectMocks
    private RepeatPriceChangeServiceImpl service;

    @Test
    @DisplayName("场景描述")
    void testScenario() throws Exception {
        // Given - 构建测试数据
        SomeDTO dto = new SomeDTO();
        dto.setField(value);
        Context context = buildContext(dto);

        // When - 通过反射调用私有方法
        ResultType result = invokePrivateMethod(context);

        // Then
        assertTrue(result.isSuccess());
    }

    /**
     * 通过反射调用私有方法
     * ⚠️ 泛型返回值需要 @SuppressWarnings("unchecked")
     */
    @SuppressWarnings("unchecked")
    private ReturnType invokePrivateMethod(ParamType context) throws Exception {
        try {
            java.lang.reflect.Method method = ServiceClass.class.getDeclaredMethod("methodName", ParamType.class);
            method.setAccessible(true);
            return (ReturnType) method.invoke(service, context);
        } catch (Exception e) {
            // 解包 InvocationTargetException
            if (e.getCause() instanceof ExpectedException) {
                throw (ExpectedException) e.getCause();
            }
            throw new RuntimeException("反射调用失败", e);
        }
    }
}
```

## 关键点

1. **JUnit 5 注解**: `@ExtendWith(MockitoExtension.class)` + `@Test` + `@DisplayName`
2. **反射调用**: `getDeclaredMethod` + `setAccessible(true)` + `invoke`
3. **异常解包**: `InvocationTargetException` 需要 `.getCause()` 获取真实异常
4. **常量注入**: 如果类中有 `private static final` 常量，用 `ReflectionTestUtils.setField` 设置

## 测试场景覆盖清单

对于过滤/校验类方法，必须覆盖：
- ✅ 条件命中（被过滤）
- ✅ 条件不命中（通过）
- ✅ 边界值（null、0、空集合）
- ✅ 多条件组合
