# WhiZper

WhiZper represents the future of social media, prioritizing privacy and freedom of expression, and offering a truly anonymous platform for users worldwide to create secret communities and speak freely. 🥷🏻

Users of WhiZper can anonymously create a group, join a group and send messages. The system is protected by **mobile biometrics authentication** and **zero knowledge proofs**.

## Architecture

-   [📄 contracts](./contracts): WhiZper smart contracts. It extends @iden3/contracts `EmbeddedZKPVerifier` to verify on-chain proofs and control creating group and sending messages.
-   [🎯 lib](./lib): WhiZper flutter code. It implements the Privado ID protocol and the UI of the mobile app.
    -   [ios](./ios): Specific settings in iOS system.
    -   [android](./android) Sepcific settings in Android system.
-   [🧩 subgraph](./subgraph): WhiZper's onchain subgraph.

## Installation

1. Run `flutter pub get` from example directory.
2. Configure the environment with the following `.env`, or copy `env.sample` and fill your the keys.
3. Run `build_runner` to generate `.g.dart` files:
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```

## Run

```bash
flutter run
```

and choose the device (now it only works for iOS device and Android)

## Technology

1. [Privado.iD](https://www.privado.id/): Privado ID protocol is used to verify the users' credentials.
2. Scaling technologies: WhiZper wants to bring **privacy** to the whole EVM ecosystems. We deployed WhiZper smart contract on many Layer2 or EVM-compatible chains to scale the ZKPs. See [contracts](./contracts) for more deployments.
3. [The Graph](https://thegraph.com/): The Graph is used to store and query on-chain data. See [subgraph](./subgraph) for the deployments.

## Future work

-   **Customize users credentials**: Group creators can decide the users who join the group should have which data. For example: more than 20 years old, joined some hackathon event before.
-   **Encrypt messages**: Now the messages are not encrypted, but it can be done by Privado credentials very easily. See [example schemas](./schemas).
-   **Improve infrastructures**: Now the main resources are host by iden3 and Polygon, but the Privado ID is EVM compatible. There should be more decentralized issuers and verifiers.
-   **Improve UI/UX**: Support more functions in a chat app, support better UX, smooth onchain experience.
