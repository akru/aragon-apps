/*
 * SPDX-License-Identitifer:    GPL-3.0-or-later
 */

pragma solidity 0.4.24;

import "@aragon/os/contracts/apps/AragonApp.sol";
import "@aragon/os/contracts/common/IForwarder.sol";

import "@aragon/apps-token-manager/contracts/TokenManager.sol";

contract Voting is IsContract, AragonApp {
    bytes32 public constant UP_KARMA_ROLE = keccak256("UP_KARMA_ROLE");
    bytes32 public constant AVOID_KARMA_ROLE = keccak256("AVOID_KARMA_ROLE");
    bytes32 public constant AUTHOR_ROLE = keccak256("AUTHOR_ROLE");

    string private constant ERROR_NO_VESTING = "KARMA_NO_POST";
    string private constant ERROR_TOKEN_NOT_CONTRACT = "KARMA_TOKEN_NOT_CONTRACT";

    struct Post {
        address author;
        bytes   content;
    }

    TokenManager public token;

    // We are mimicing an array, we use a mapping instead to make app upgrade more graceful
    mapping (uint256 => Post) internal posts;
    uint256 public postsLength;

    event PostPublished(uint256 indexed postId, address indexed author);
    event KarmaChanged(address indexed author, uint256 indexed karma);

    modifier postExists(uint256 _postId) {
        require(_postId < postLength, ERROR_NO_POST);
        _;
    }

    /**
    * @notice Initialize Karma app
    * @param _token TokenManager Address of karma token manager
    */
    function initialize(
        TokenManager _token,
    )
        external
        onlyInit
    {
        initialized();
        require(isContract(_token, ERROR_TOKEN_NOT_CONTRACT));

        token = _token;
    }

    /**
    * @notice Up karma balance for account 
    * @param _author target address 
    */
    function up(address _author)
        external
        authP(UP_KARMA_ROLE, arr(_author))
    {
        require(token.balanceOf(msg.sender) > 0);

        token.mint(_author, 1);
        emit KarmaChanged(_author, token.balanceOf(_author));
    }

    /**
    * @notice Avoid karma balance for account 
    * @param _author target address 
    */
    function avoid(address _author)
        external
        authP(AVOID_KARMA_ROLE, arr(_author))
    {
        token.burn(_author, token.balanceOf(_author));
        emit KarmaChanged(_author, token.balanceOf(_author));
    }

    /**
    * @notice Publish new post to blog 
    * @param _author post author  
    * @param _content post content IPFS hash
    */
    function newPost(address _author, bytes calldata _content)
        external
        authP(AUTHOR_ROLE, arr(_author))
    {
        require(token.balanceOf(msg.sender) > 0);

        posts.push(Post(_author, _content));
        emit PostPublished(postsLength, _author);
        ++postsLength;
    }

    /**
    * @notice Get post by id 
    */
    function getPost(uint256 _postId)
        public
        view
        postExists(_postId)
        returns (
            address author,
            bytes   content
        )
    {
        Post storage post_ = posts[_postId];

        author  = post_.author;
        content = post_.content;
    }
}
