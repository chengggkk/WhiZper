import { newMockEvent } from "matchstick-as"
import { ethereum, BigInt } from "@graphprotocol/graph-ts"
import { Group, Message } from "../generated/WhiZper/WhiZper"

export function createGroupEvent(
  groupId: BigInt,
  userId: BigInt,
  groupName: string
): Group {
  let groupEvent = changetype<Group>(newMockEvent())

  groupEvent.parameters = new Array()

  groupEvent.parameters.push(
    new ethereum.EventParam(
      "groupId",
      ethereum.Value.fromUnsignedBigInt(groupId)
    )
  )
  groupEvent.parameters.push(
    new ethereum.EventParam("userId", ethereum.Value.fromUnsignedBigInt(userId))
  )
  groupEvent.parameters.push(
    new ethereum.EventParam("groupName", ethereum.Value.fromString(groupName))
  )

  return groupEvent
}

export function createMessageEvent(
  groupId: BigInt,
  userId: BigInt,
  message: string
): Message {
  let messageEvent = changetype<Message>(newMockEvent())

  messageEvent.parameters = new Array()

  messageEvent.parameters.push(
    new ethereum.EventParam(
      "groupId",
      ethereum.Value.fromUnsignedBigInt(groupId)
    )
  )
  messageEvent.parameters.push(
    new ethereum.EventParam("userId", ethereum.Value.fromUnsignedBigInt(userId))
  )
  messageEvent.parameters.push(
    new ethereum.EventParam("message", ethereum.Value.fromString(message))
  )

  return messageEvent
}
