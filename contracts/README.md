# WhiZper contracts

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/WhiZper.ts
```

## Deploy on specified network

Create an `.env` file with

```shell
INFURA_API_KEY=YOUR_INFURA_API_KEY
PRIVATE_KEY=YOUR_PRIVATE_KEY
```

```shell
npx hardhat run ./scripts/deploy.ts --network sepolia
```

Supporting networks

-   polygon
-   sepolia
-   amoy
-   arbitrum
-   zircuit
-   rootstock
-   jenkins
-   scroll
-   linea

## ZK deployment v2

1. polygon: `0x5D6B85dcFA6df2aDfdca08EFDd1dAa2e0e0B5d2F`
2. sepolia: `0x230d89fE5035c3860fc4d04cD32cB64A3b16fE90`
3. arbitrum-sepolia: `0x83534E9D36076D04bD404c1173e8B4A5D0D42325`
4. jenkins: `0x0c635B4cBAb677ba09C5305c977590262356fC24`
5. zircuit: `0x0c635B4cBAb677ba09C5305c977590262356fC24`
6. scroll: `0xE95210e97F80cA87FE07F34e3817A4B954672534`

## ZK deployment

1. sepolia: `0x0d72F012CE41ebCd5D148bf3b30Bf54379b799E7`
2. arbitrum-sepolia: `0xE9956Ab4a5338B8A9b61f033700219fD6FbfCd32`
3. jenkins: `0x89a445543dE297562fA2683b5C10303759b906b9`
4. zircuit: `0x89a445543dE297562fA2683b5C10303759b906b9`
5. scroll: `0x89a445543dE297562fA2683b5C10303759b906b9`

## Non ZK deployment

1. sepolia: `0xDce69DC9a55B79C84022BA5402496F64A12FE4dB`
2. amoy: `0x89a445543dE297562fA2683b5C10303759b906b9`
3. arbitrum-sepolia: `0xF4205f466De67CA37d820504eb3c81bb89081214`
