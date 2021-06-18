# copier
A mod made for Minetest events, to copy and paste a block from/to a file or from/to a in-game tool.
## License
 - Code: LGPLv2.1
 - Media: CC BY-SA 4.0, Cato Yiu
## Usage
### In-game tool
#### `copier:copier`
The main tool of the mod. Punch a node to copy it.
#### `copier:copier:ready`
The copier with a copied node inside. Right click a node to paste the copied node to that place, and punch a node to change the copied node.
#### Limits
 - You cannot copy or paste nodes that is locked but not owned by you.
 - You cannot paste blocks in protected areas.
### Exporting commands
#### `/copier_export <save file name>`
Export the copier infomation to the specified file. You must wield a ready copier while using this command. This command requires the `server` priv to avoid griefers save a lot of copied blocks to the filesystem then make it full.
#### `/copier_import <save file name>`
Import the copier infomation from specified file to a dropped item under you. This command requires the `creative` priv.
