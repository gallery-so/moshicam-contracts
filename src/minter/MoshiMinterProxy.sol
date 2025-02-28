// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/*

                                    #######################
                                    ###                 ###
                                    ###                 ###
                                    ###  ##        ##   ###
                                    ###  ##   ##   ##   ###
                                    ###       ##        ###
                                    ###                 ###
                                    ###    ##    ##     ###
                                    ###     ######      ###
                                    ###                 ###
                                    ###                 ###
                                    #######################
                                    #######################
                                    #######################
                                    #######################

               ######    ######     ##########     #########  ######   #####  #####
              ########  ########   #############  ########### ######  ###### ######
              ########  ########  ######  ###### #######  ##  ######  ###### ######
             ###################  #####    ###### ######      ####### ###### ######
             ################### ######    ######  #########  ############## ######
             ##########################    ######    ######## ############## ######
             ##### ####### ###### ######   ######      #############  ###### ######
             #####  ###### ###### ############## ############ ######  ###### ######
             #####  ######  #####  ############  ############ ######  ###### ######
             #####   ####   #####    ########      ########    ####    #####  ####

                            #####          ###           ###       ###
                         ###########     #######       #######   #######
                        ############    #########     ########  ########
                       ######   ###     ##########    ######### #########
                      ######           ##### #####    ###################
                      ######           #####  #####   ###################
                      ######          ######  #####   ###################
                       ######    ##   ############## ###### ####### #####
                       ############# ###################### ######  ######
                         ########### ######    ############  #####  ######
                           #######    ###       ####  ####    ###    ####

                        (∩｀V´)⊃━☆ﾟ.*･｡ﾟ ･* MOSHI.CAM *･ (C) GALLERY LABS 2024


*/

contract MoshiMinterProxy is ERC1967Proxy {
    constructor(address implementation, bytes memory data) ERC1967Proxy(implementation, data) {}
}
