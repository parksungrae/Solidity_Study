# Overriding

override 가능한 요소에 virtual을, override하는 요소에는 override 붙혀줘야함
```jsx
interface IA {
    function a() public view returns (string memory)
}

contract A is IA {
    function a() public view virtual override returns(string memory){
        return "a"
    }
}

```