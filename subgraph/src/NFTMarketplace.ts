import {
  ItemListed,
  ItemBought,
  ItemCancelled,
  ItemUpdated,
} from "../generated/NFTMarketplace/NFTMarketplace";
import { Item } from "../generated/schema";

export function handleItemListed(event: ItemListed) {
  let entity = new Item(
    event.params.NFTAddress.toHex() +
      event.params.tokenId.toString() +
      event.params.sellerAddress.toHex()
  );
  entity.NFTAddress = event.params.NFTAddress;
  entity.tokenId = event.params.tokenId;
  entity.sellerAddress = event.params.sellerAddress;
  entity.price = event.params.price;
  entity.blockNumberListed = event.block.number;
  entity.save();
}

export function handleItemBought(event: ItemBought) {
  let entity = new Item(
    event.params.NFTAddress.toHex() +
      event.params.tokenId.toString() +
      event.params.sellerAddress.toHex()
  );
  entity.blockNumberBought = event.block.number;
  entity.save();
}

export function handleItemCancelled(event: ItemCancelled) {
  let entity = new Item(
    event.params.NFTAddress.toHex() +
      event.params.tokenId.toString() +
      event.params.sellerAddress.toHex()
  );
  entity.blockNumberCancelled = event.block.number;
  entity.save();
}

export function handleItemUpdated(event: ItemUpdated) {
  let entity = new Item(
    event.params.NFTAddress.toHex() +
      event.params.tokenId.toString() +
      event.params.sellerAddress.toHex()
  );
  entity.price = event.params.price;
  entity.save();
}
