# unchecked

overflow검사를 하지 않을 범위를 설정해줌으로 가스비를 절약함

```jsx
function subtraction(uint a, uint b) public view returns(uint){

  //a가 무조건 b보다 큰지 확인
  require(a>b, "b is bigger than a");

  //require문으로 a가 클수밖에 없기에 overflow되지 않음
  unchecked {
    a = a - b;
  }
  
  return a;
}

```