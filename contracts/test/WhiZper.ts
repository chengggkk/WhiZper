import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import hre from "hardhat";

describe("WhiZper", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployWhiZperFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await hre.ethers.getSigners();

    const WhiZper = await hre.ethers.getContractFactory("WhiZper");
    const whizper = await WhiZper.deploy();

    return { whizper, owner, otherAccount };
  }

  describe("Deployment", function () {

    it("Should set the right owner", async function () {
      const { whizper, owner } = await loadFixture(deployWhiZperFixture);

      expect(await whizper.owner()).to.equal(owner.address);
    });

  });

  describe("Group", function () {
    describe("Create group", function () {
      it("Should create a group", async function () {
        const { whizper } = await loadFixture(deployWhiZperFixture);
        const groupId = 0
        const userId = 2
        const groupName = "test"

        await expect(whizper.createGroup(userId, groupName))
          .to.emit(whizper, "Group")
          .withArgs(groupId, userId, groupName); // We accept any value as `when` arg
      });

      describe("Join group", function () {
        it("Should join a group", async function () {
          const { whizper } = await loadFixture(deployWhiZperFixture);
          const groupId = 0
          const userId = 3
          // TODO: fix with groupName
          const groupName = "test"

          await expect(whizper.joinGroup(groupId, userId))
            .to.emit(whizper, "Group")
            .withArgs(groupId, userId, ""); // We accept any value as `when` arg
        });
      });
    });
  });

  describe("Chat", function () {

    it("Should send message", async function () {
      const { whizper, owner } = await loadFixture(deployWhiZperFixture);

      const groupId = 0
      const userId = 3
      const groupName = "test"
      const message = "test msg"

      await expect(whizper.createGroup(userId, groupName))
        .to.emit(whizper, "Group")
        .withArgs(groupId, userId, groupName); // We accept any value as `when` arg

      await expect(whizper.sendMessage(groupId, userId, message))
        .to.emit(whizper, "Message")
        .withArgs(groupId, userId, message); // We accept any value as `when` arg
    });

  });
});
