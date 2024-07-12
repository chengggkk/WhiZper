import {
  Group as GroupEvent,
  Message as MessageEvent
} from "../generated/WhiZper/WhiZper"
import { Group, Message } from "../generated/schema"

export function handleGroup(event: GroupEvent): void {
  let entity = new Group(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.groupId = event.params.groupId
  entity.userId = event.params.userId
  entity.groupName = event.params.groupName

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleMessage(event: MessageEvent): void {
  let entity = new Message(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.groupId = event.params.groupId
  entity.userId = event.params.userId
  entity.message = event.params.message

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}
