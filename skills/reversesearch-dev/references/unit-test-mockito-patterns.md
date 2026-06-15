# Mockito + 反射测试私有方法模式

## 适用场景
测试 `RepeatPriceChangeServiceImpl` 等 service 中的 private 方法（如 `matchChangeOrder`）。

## 标准测试模板

```java
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
public class XxxServiceImplTest {

    @InjectMocks
    private XxxServiceImpl xxxService;

    @Mock
    private DateConverter dateConverter;  // 所有 @Resource 注入的依赖都需要 mock

    @BeforeEach
    void setUp() {
        when(dateConverter.asDate(anyString())).thenReturn(new Date());
    }

    @Test
    void testXxx() throws SearchBizException {
        // Given
        ChangeInfoDTO changeInfoDTO = buildChangeInfoDTO(...);
        RepeatChangePriceContext context = buildContext(Lists.newArrayList(changeInfoDTO));

        // When
        ValidResult<ChangeInfoDTO> result = invokeMatchChangeOrder(context);

        // Then
        assertFalse(result.isSuccess());
    }

    /** 通过反射调用私有方法 */
    @SuppressWarnings("unchecked")
    private ValidResult<ChangeInfoDTO> invokeMatchChangeOrder(RepeatChangePriceContext context) throws SearchBizException {
        try {
            java.lang.reflect.Method method = XxxServiceImpl.class.getDeclaredMethod("matchChangeOrder", RepeatChangePriceContext.class);
            method.setAccessible(true);
            return (ValidResult<ChangeInfoDTO>) method.invoke(xxxService, context);
        } catch (Exception e) {
            if (e.getCause() instanceof SearchBizException) {
                throw (SearchBizException) e.getCause();
            }
            throw new RuntimeException("反射调用失败", e);
        }
    }
}
```

## ChangeInfoDTO 测试数据构造要点

```java
private ChangeInfoDTO buildChangeInfoDTO(Integer mailState, Integer cancelChangeState, Integer changeSubType) {
    ChangeInfoDTO dto = new ChangeInfoDTO();
    dto.setChangeSerialNo("TEST_CHANGE_001");
    dto.setId(1L);                                    // 必须！sorted() 比较用
    dto.setChangeState(ChangeStateEnum.CANCELED.getCode());
    dto.setChangeType(ChangeTypeEnum.CHANGE.getCode()); // 必须！filter() 用
    dto.setMailState(mailState);
    dto.setChangeSubType(changeSubType);

    // extDTO - cancelChangeState 必须设置
    ChangeExtDTO extDTO = new ChangeExtDTO();
    extDTO.setUserCancel(true);
    extDTO.setCancelChangeState(cancelChangeState);
    dto.setExtDTO(extDTO);

    // psis - 乘客和航段信息
    PSIDTO psi = new PSIDTO();
    SegmentDTO segment = new SegmentDTO();
    segment.setSegmentId("SEG_001");
    segment.setSequence(1);
    segment.setDepartureAirportCode("PEK");
    segment.setArrivalAirportCode("SHA");
    segment.setFlightNo("CA1234");
    segment.setCabinCode("Y");
    segment.setGmtTakeOff("2026-06-09 12:00:00");  // String 类型！不是 Date
    psi.setSegment(segment);

    PassengerDTO passenger = new PassengerDTO();
    passenger.setOrderPassengerId("PASSENGER_001");
    psi.setPassenger(passenger);
    psi.setDealType(ChangeDealTypeEnum.CHANGE.getCode());

    dto.setPsis(Lists.newArrayList(psi));
    return dto;
}
```

## RepeatChangePriceContext 构造要点

```java
private RepeatChangePriceContext buildContext(List<ChangeInfoDTO> changeOrders) {
    RepeatChangePriceContext context = new RepeatChangePriceContext();
    context.setChangeOrders(changeOrders);
    context.setPassengerIdList(Lists.newArrayList("PASSENGER_001"));

    // newSegments 类型是 RepeatSegmentPriceVO，不是 FlightUniformSegmentVO！
    RepeatSegmentPriceVO newSegment = new RepeatSegmentPriceVO();
    newSegment.setSequence(1);
    newSegment.setOriginSegmentId("SEG_001");
    newSegment.setDepartureAirportCode("PEK");
    newSegment.setArrivalAirportCode("SHA");
    newSegment.setFlightNo("CA1234");
    newSegment.setCabinCode("Y");
    newSegment.setGmtTakeOff("2026-06-09 12:00:00");
    context.setNewSegments(Lists.newArrayList(newSegment));

    // 必须初始化！否则 .size() 调用 NPE
    context.setConfirmedSegments(new ArrayList<>());
    context.setConfirmedCabins(new ArrayList<>());

    return context;
}
```

## 关键枚举值

| 枚举 | 可用值 | 说明 |
|------|--------|------|
| ChangeSubTypeEnum | VOLUNTARY_CHANGE, DELAY_CHANGE | NORMAL_CHANGE 不存在 |
| ChangeStateEnum | CANCELED, USER_CONFIRM | |
| ChangeTypeEnum | CHANGE | |
| ChangeDealTypeEnum | CHANGE | |
