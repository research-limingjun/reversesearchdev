# reverseauxiliary 集成模式参考

## 概述

reversesearch 项目通过 Dubbo RPC 调用 reverseauxiliary 服务。集成代码位于 `app/integration/` 模块。

## 依赖配置

**pom.xml (integration 模块)**:
```xml
<dependency>
    <groupId>com.ly.flight.intl</groupId>
    <artifactId>reverseauxiliary-facade</artifactId>
</dependency>
<dependency>
    <groupId>com.ly.flight.intl</groupId>
    <artifactId>reverseauxiliary-model</artifactId>
</dependency>
```

## Dubbo 配置

**文件**: `app/integration/src/main/resources/META-INF/spring/reversesearch-integration-rpc-beans-xml.xml`

```xml
<!-- 国际机票退改辅营核心 -->
<sof:reference id="auxiliaryCoreFacade"
               serviceName="goodscore"
               gsName="${integration.reverseauxiliary.gsName}"
               interface="com.ly.flight.intl.reverseauxiliary.facade.GoodsCoreFacade"
               version="${integration.reverseauxiliary.version}"
               timeout="30000"
               retries="2" serializer="FASTJSON">
    <sof:method name="reverseGoodsQuery" paramType="bodyParam" timeout="10000"/>
    <sof:method name="goodsList" paramType="bodyParam" timeout="10000"/>
</sof:reference>
```

**版本配置** (在 dubbo.properties 中):
- qa: `integration.reverseauxiliary.version=1.2.0.4`
- uat: `integration.reverseauxiliary.version=1.5.0.0`

## 客户端模式

项目使用 Client 模式封装外部服务调用：

### 目录结构
```
app/integration/src/main/java/com/ly/flight/intl/reversesearch/integration/client/
├── reverseauxiliary/                  # 辅营服务客户端
│   └── ReverseAuxiliaryClientImpl.java
├── goodsorder/                        # 商品单相关客户端
│   ├── GoodsOrderCheckClient.java     # 接口
│   └── impl/
│       └── GoodsOrderCheckClientImpl.java  # 实现
├── refundcore/                        # 退订核心客户端
│   ├── RefundQueryClient.java
│   └── impl/
│       └── RefundQueryClientImpl.java
└── ...
```

### 客户端接口示例

```java
package com.ly.flight.intl.reversesearch.integration.client.goodsorder;

import com.ly.flight.intl.reverseauxiliary.facade.response.goodscore.query.CheckProcessingGoodsResponseDTO;
import com.ly.flight.intl.reversebase.integration.exception.IntegrationException;

public interface GoodsOrderCheckClient {
    CheckProcessingGoodsResponseDTO checkProcessingGoods(String orderSerialNo) throws IntegrationException;
}
```

### 客户端实现示例

**ReverseAuxiliaryClientImpl** (辅营服务客户端，调用 goodsList):
```java
package com.ly.flight.intl.reversesearch.integration.client.reverseauxiliary;

import com.ly.flight.intl.reverseauxiliary.facade.GoodsCoreFacade;
import com.ly.flight.intl.reverseauxiliary.facade.request.goodscore.GoodsListRequestDTO;
import com.ly.flight.intl.reverseauxiliary.facade.response.goodscore.GoodsListResponseDTO;
import com.ly.flight.intl.reversebase.integration.client.aop.IntegrationLogCfg;
import com.ly.flight.intl.reversebase.integration.exception.IntegrationException;
import org.springframework.stereotype.Service;
import javax.annotation.Resource;

@Service
public class ReverseAuxiliaryClientImpl {
    @Resource
    private GoodsCoreFacade auxiliaryCoreFacade;

    @IntegrationLogCfg(interfaceName = "查询订单商品单列表", successMethod = "isSuccess", errorCodeMethod = "getErrorCode", errorMessageMethod = "getErrorMessage")
    public GoodsListResponseDTO goodsList(String orderSerialNo) throws IntegrationException {
        GoodsListRequestDTO requestDTO = new GoodsListRequestDTO();
        requestDTO.setOrderSerialNo(orderSerialNo);
        return this.auxiliaryCoreFacade.goodsList(requestDTO);
    }
}
```

**GoodsOrderCheckClientImpl** (商品单校验客户端):
package com.ly.flight.intl.reversesearch.integration.client.goodsorder.impl;

import com.ly.flight.intl.reverseauxiliary.facade.GoodsCoreFacade;
import com.ly.flight.intl.reverseauxiliary.facade.request.goodscore.query.CheckProcessingGoodsRequestDTO;
import com.ly.flight.intl.reverseauxiliary.facade.response.goodscore.query.CheckProcessingGoodsResponseDTO;
import com.ly.flight.intl.reversebase.integration.client.aop.IntegrationLogCfg;
import com.ly.flight.intl.reversebase.integration.exception.IntegrationException;
import com.ly.flight.intl.reversesearch.integration.client.goodsorder.GoodsOrderCheckClient;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;

@Service
public class GoodsOrderCheckClientImpl implements GoodsOrderCheckClient {

    @Resource
    private GoodsCoreFacade auxiliaryCoreFacade;

    @Override
    @IntegrationLogCfg(
        interfaceName = "检查处理中商品单",
        successMethod = "isSuccess",
        errorCodeMethod = "getErrorCode",
        errorMessageMethod = "getErrorMessage"
    )
    public CheckProcessingGoodsResponseDTO checkProcessingGoods(String orderSerialNo) throws IntegrationException {
        CheckProcessingGoodsRequestDTO requestDTO = new CheckProcessingGoodsRequestDTO();
        requestDTO.setOrderSerialNo(orderSerialNo);
        return this.auxiliaryCoreFacade.checkProcessingGoods(requestDTO);
    }
}
```

## GoodsCoreFacade 可用方法

### 版本 3.2.8.RELEASE
- `reverseGoodsQuery` - 退改商品查询
- `reverseGoodsCreate` - 退改商品创建
- `reverseGoodsCancel` - 退改商品取消
- `reverseGoodsHandle` - 退改商品处理
- `merchantAppealCreate` - 商户申诉创建
- `goodsDetail` - 商品详情
- `goodsList` - 商品列表
- `queryGoodsBillMonthInfo` - 商品账单月信息
- `queryOrderRefundHistories` - 订单退票历史

### 版本 3.3.42.RELEASE (新增)
- `goodsDetailList` - 商品详情列表
- `queryGoodsOrderByList` - 按列表查询商品订单
- `getCheckRate` - 获取检查率
- `queryGoodsItemList` - 查询商品项列表
- `checkStateUpdate` - 检查状态更新
- `reverseGoodsBakFlag` - 退改商品备份标志
- `fyGoodsLock` - 飞友商品锁定
- `speedChangeGoodsQuery` - 极速改签商品查询

### 待实现 (需要 reverseauxiliary 开发)
- `checkProcessingGoods` - 检查处理中商品单
- `checkGoodsOrderExist` - 校验订单是否存在商品单（在特性分支 `feat/TASK-003-check-goods-order-exist`，未合并到 master）

## 常用 DTO 参考

### GoodsListRequestDTO
- `orderSerialNo` (String) - 订单号
- `goodsType` (Integer) - 商品类型 (0:默认/1:退订/2:改签/3:航变)
- `goodsSubType` (Integer) - 商品子类型
- `goodsState` (Integer) - 商品单状态

### GoodsListResponseDTO
- `goodsInfos` (List\<GoodsDTO\>) - 商品明细数据列表，非空即表示存在商品单

## 验证接口是否可用

```bash
# 1. 查找版本
ls ~/.m2/repository/com/ly/flight/intl/reverseauxiliary-facade/

# 2. 检查方法
cd /tmp && mkdir check-facade && cd check-facade
jar xf ~/.m2/repository/com/ly/flight/intl/reverseauxiliary-facade/3.3.42.RELEASE/reverseauxiliary-facade-3.3.42.RELEASE.jar com/ly/flight/intl/reverseauxiliary/facade/GoodsCoreFacade.class
javap -public com/ly/flight/intl/reverseauxiliary/facade/GoodsCoreFacade.class
```
