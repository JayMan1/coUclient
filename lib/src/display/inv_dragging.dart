part of couclient;

class InvDragging {
	static List<String> disablers = [];
	static Service refresh;
	/// Draggable items
	static Draggable draggables;
	/// Drop targets
	static Dropzone dropzones;

	static Element currentlyDisplaced, origBox;

	/**
	 * Map used to store *how* the item was moved.
	 * Keys:
	 * - General:
	 * - - item_number: element: span element containing the count label
	 * - - bag_btn: element: the toggle button for containers
	 * - On Pickup:
	 * - - fromBag: boolean: whether the item used to be in a bag
	 * - - fromBagIndex: int: which slot the toBag is in  (only set if fromBag is true)
	 * - - fromIndex: int: which slot the item used to be in
	 * - On Drop:
	 * - - toBag: boolean: whether the item is going into a bag
	 * - - toBagIndex: int: which slot the toBag is in (only set if toBag is true)
	 * - - toIndex: int: which slot the item is going to
	 */
	static Map<String, dynamic> move = {};

	/// Checks if the specified slot is empty
	static bool slotIsEmpty({int index, Element box, int bagWindow}) {
		if (index != null) {
			if (bagWindow == null) {
				box = querySelectorAll("#inventory .box").toList()[index];
			} else {
				box = querySelectorAll("#bagWindow$bagWindow").toList()[index];
			}
		}

		return (box.children.length == 0);
	}

	/// Set up event listeners based on the current inventory
	static void init() {
		if (refresh == null) {
			refresh = new Service(["inventoryUpdated"], (_) => init());
		}
		// Remove old data
		if (draggables != null) {
			draggables.destroy();
		}
		if (dropzones != null) {
			dropzones.destroy();
		}

		if (disablers.length == 0) {
			// Set up draggable elements
			draggables = new Draggable(
				// List of item elements in boxes
				querySelectorAll('.inventoryItem'),
				// Display the item on the cursor
				avatarHandler: new CustomAvatarHandler(),
				// If a bag is open, allow free dragging.
				// If not, only allow horizontal dragging across the inventory bar
				horizontalOnly: !BagWindow.isOpen,
				// Disable item interaction while dragging it
				draggingClass: "item-flying"
			)
				..onDragStart.listen((DraggableEvent e) => handlePickup(e));

			// Set up acceptor slots
			dropzones = new Dropzone(querySelectorAll("#inventory .box"))
				..onDrop.listen((DropzoneEvent e) => handleDrop(e));
		}
	}

	/// Runs when an item is picked up (drag start)
	static void handlePickup(DraggableEvent e) {
		origBox = e.draggableElement.parent;
		e.draggableElement.dataset["original-slot-num"] = origBox.dataset["slot-num"];

		move = {};

		if (querySelector("#windowHolder").contains(origBox)) {
			move['fromIndex'] = int.parse(origBox.parent.parent.dataset["source-bag"]);
			move["fromBagIndex"] = int.parse(origBox.dataset["slot-num"]);
		} else {
			move['fromIndex'] = int.parse(origBox.dataset["slot-num"]);
		}
	}

	/// Runs when an item is dropped (drop)
	static void handleDrop(DropzoneEvent e) {
		if (querySelector("#windowHolder").contains(e.dropzoneElement)) {
			move["toIndex"] = int.parse(e.dropzoneElement.parent.parent.dataset["source-bag"]);
			move["toBagIndex"] = int.parse(e.dropzoneElement.dataset["slot-num"]);
		} else {
			move["toIndex"] = int.parse(e.dropzoneElement.dataset["slot-num"]);
		}

		sendAction("moveItem", "global_action_monster", move);
	}
}

class BagFilterAcceptor extends Acceptor {
	BagFilterAcceptor(this.allowedItemTypes);

	List<String> allowedItemTypes;

	@override
	bool accepts(Element itemE, int draggable_id, Element box) {
		ItemDef item = decode(itemE.attributes['itemmap'],type:ItemDef);
		if (allowedItemTypes.length == 0) {
			// Those that accept nothing learn to accept everything (except other containers)
			return !item.isContainer;
		} else {
			// Those that are at least somewhat accepting are fine, though
			return allowedItemTypes.contains(item.itemType);
		}
	}
}