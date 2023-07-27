// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721} from "solady/tokens/ERC721.sol";
import {ICryptoPunksData} from "./ICryptoPunksData.sol";
import {LibString} from "solady/utils/LibString.sol";
import {json} from "sol-json/json.sol";

abstract contract PunksWrapperMetadata is ERC721 {
    using LibString for string;
    using LibString for uint256;

    ICryptoPunksData public constant PUNKS_DATA = ICryptoPunksData(0x16F5A35647D6F03D5D3da7b35409D65ba03aF3B2);

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist();
        }
        uint16 punkIndex = uint16(tokenId);
        string memory imageData = PUNKS_DATA.punkImageSvg(punkIndex);
        string memory attributes = PUNKS_DATA.punkAttributes(punkIndex);

        attributes = parseAttributesArray(attributes);
        return json.object(
            string.concat(json.property("image", imageData), ",", json.rawProperty("attributes", attributes))
        );
    }

    function parseAttributesArray(string memory attributes) internal pure returns (string memory parsed) {
        string[] memory individualTraits = attributes.split(string(","));

        uint256 count = individualTraits.length - 1;
        string[] memory attributesArray = new string[](individualTraits.length + 1);
        attributesArray[0] = createAttribute("Type", individualTraits[0]);
        string memory trait = "Accessory";
        for (uint256 i = 1; i < individualTraits.length; i++) {
            attributesArray[i] = createAttribute(trait, individualTraits[i]);
        }
        attributesArray[individualTraits.length] = createAttribute("Attribute Count", count.toString());

        for (uint256 i; i < attributesArray.length; i++) {
            parsed = string.concat(parsed, attributesArray[i]);
            if (i != attributesArray.length - 1) {
                parsed = string.concat(parsed, ",");
            }
        }
        return json.array(parsed);
    }

    function createAttribute(string memory trait, string memory value) internal pure returns (string memory) {
        return json.object(string.concat(json.property("trait_type", trait), ",", json.property("value", value)));
    }
}