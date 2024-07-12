import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as"
import { BigInt } from "@graphprotocol/graph-ts"
import { Group } from "../generated/schema"
import { Group as GroupEvent } from "../generated/WhiZper/WhiZper"
import { handleGroup } from "../src/whi-zper"
import { createGroupEvent } from "./whi-zper-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/developer/matchstick/#tests-structure-0-5-0

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let groupId = BigInt.fromI32(234)
    let userId = BigInt.fromI32(234)
    let groupName = "Example string value"
    let newGroupEvent = createGroupEvent(groupId, userId, groupName)
    handleGroup(newGroupEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/developer/matchstick/#write-a-unit-test

  test("Group created and stored", () => {
    assert.entityCount("Group", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "Group",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "groupId",
      "234"
    )
    assert.fieldEquals(
      "Group",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "userId",
      "234"
    )
    assert.fieldEquals(
      "Group",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "groupName",
      "Example string value"
    )

    // More assert options:
    // https://thegraph.com/docs/en/developer/matchstick/#asserts
  })
})
