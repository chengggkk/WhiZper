import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const WhiZperModule = buildModule("WhiZperModule", (m) => {
    const whizper = m.contract("WhiZper", [], {
    });

    return { whizper };
});

export default WhiZperModule;
