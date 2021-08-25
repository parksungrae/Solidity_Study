// SPDX-License-Identifier: MIT

//solidity version 설정 ^는 0.8중 0.8.0 이상을 의미
pragma solidity ^0.8.0;

//import로 다른 sol파일 불러오기
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {

    // address의 ether 잔고
    mapping(address => uint256) private _balances;

    //address1 이 address2에 허용할 만큼의 ether 양
    //내가 나의 ether를 맡겼을 때 이득을 볼 수 있을 때 ex: swap, yield farming 등 allowances가 없을 시 구조가 복잡했을 것
    // 이 이상의 ether의 해킹을 막을 수 있음
    mapping(address => mapping(address => uint256)) private _allowances;

    //토큰의 총 공급량
    uint256 private _totalSupply;

    //name과 symbol은 변경시 혼란을 일으키거나 토큰 관련 서비스의 에러를 일으킬수 있기에 변경 대부분 X

    //토큰의 이름 ex ethereum
    string private _name;

    //토큰의 심볼 ex ETH
    string private _symbol;

    /**
     * @dev {name} 과 {symbol} 값을 설정.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev name이 private기에 참조할 수 있게 만드는 함수
      virtual : 상속받아 마음대로 튜닝 가능
      override : IERC20에 선언된 name함수를 덮어쓰기에 override 선언
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev symbol이 private기에 참조할 수 있게 만드는 함수
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev 토큰의 최소 단위를 설정 
     *      decimal == 2 -> 소수 2번째 자리인 0.01까지.
     *
     * ether와 wei 처럼 erc20규격에선 18을 쓰는게 일방적이다;
     *
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev 내 지갑에서 `recipment` 에게 `amount` 만큼 보낸다.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        // _는 대부분 private, internal 함수를 사용할 때 쓰임
        // 보내는사람, 받는사람, 양
        
        _transfer(_msgSender(), recipient, amount);
        
        
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev amount만큼 allowance를 할당해주다고 승인하는 함수
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev allowance를 이용하여 남의 돈을 보낼 때 사용하는 함수
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender`를 지정가능하다.
     * - `sender`와 `recipient` 0의 주소면 안된다.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        //token을 보낼 (address)에 대해 보내게 할 (_msgSender)가 얼마의 (allowance) 값을 가지고 있나
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");

        //uncheck -> overflow체크를 하지 않겠다
        //overflow가 절대 일어나지 않는 곳에 unchecked를 사용할 시 Gas를 절약할 수 있기에
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    //{increaseAllowance}, {decreaseAllowance}는 일반 {approve}의 취약점(approve 함수와 allowance 사용 함수가 동시 실행되었을 때 allowance 사용이 approve보다 빠를 때)을 줄이기 위해

    /**
     * @dev allowance양을 늘리는 함수.
     *
     * spender는 0이 될 수 없음
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {

        //addedValue : 더할 allowance
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev allowance양을 줄이는 함수.
     * 
     * spender는 0이 될 수 없음
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {

        //subtractedValue : 감할 allowance 양

        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Requirements:
     *
     * - `sender`와 `recipient` 는 빈 address를 쓸 수 없다
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {

        //잔고 확인
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        //A가 B에 만원을 보낸다 했을 때 A에서 만원 차감 B에 만원 추가를 하는 작업
        uint256 senderBalance = _balances[sender];

        //큰수에서 작은수를 빼는작업이기 때문에 unchecked
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev 토큰의 총 공급량을 감소시키고 그만큼 발행함
     *
     * address 0 에서 address 0 으로는 불가능
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;

        //Transfer event를 address(0) 코인베이스에서 발행함으로 실행함
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev account에서 일정량의 토큰을 빈 계좌로 보냄으로서 토큰을 사용못하게 하고
     * 총공급량을 감소함
     * 빈 address에서는 소각이 불가능하다
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        //owner가 spender에게 amount만큼 토큰을 사용할 수 있도록 허용
        _allowances[owner][spender] = amount;

        //승인 이벤트인 approval 실행
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev {transfer} 전에 override하여 사용 가능한 함수
     *
     * 두 주소가 모두 0이 아닐 경우 전송됨
     * 잔고가 0일경우 실패
     * 0의 address로 보낼 경우 토큰은 소각됨(burned)
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        //require문 등으로 custom
    }

    /**
     * @dev {transfer} 후에 override하여 사용 가능한 함수
     *
     * 두 주소가 모두 0이 아닐 경우 전송됨
     * 잔고가 0일경우 실패
     * 0의 address로 보낼 경우 토큰은 소각됨(burned)
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        //require문 등으로 custom
    }
}