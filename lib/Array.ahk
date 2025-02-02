

;Array.GetLastError()								마지막으로 호출한 메소드의 실패여부를 알 수 있는 에러코드를 반환한다. 파라미터로 인덱스를 지정하는 메소드와 Pop()은 실행 후 이 메소드를 호출하여 성공여부를 알 수 있다. @return 에러코드. 0이면 성공, 1이면 실패.									
;Array.Length()										배열의 엘리먼트 개수를 반환한다.
;Array.Set(idx, value)								배열의 특정 엘리먼트의 값을 설정한다. 성공하면 GetLastError()가 0을, 실패하면 1을 반환한다.
;Array.Get(idx)										배열의 특정 엘리먼트 값을 반환한다. 성공하면 GetLastError()가 0을, 실패하면 1을 반환한다.
;Array.ToString(delim=",")							배열을 구분자로 구분된 문자열로 나타내어 반환한다
;Array.Add(value)									배열에 새 엘리먼트를 추가한다. 새 엘리먼트의 인덱스는 (이전배열의 길이 + 1)이 된다.
;Array.IndexOf(value)								배열 전체를 대상으로 특정 엘리먼트를 검색한다. 만일, 이 메소드가 자주 호출되며 배열을 정렬하여도 아무런 문제가 되지 않는다면, 이보다 훨씬 빠른 BinarySearch()를 사용하는 것이 좋다.
;Array.Sort(asc=true)								배열을 정렬한다.
;Array.Insert(idx, value)
;Array.Remove(idx)
;Array.BinarySearch(key, from=1, to=Length()+1)
;Array.Shuffle()
;Array.Push(value)
;Array.Pop()
;Array.Equals(other)
;Array.Fill(value, from=1, to=Length()+1)
;Array.CopyOf(from=1, to=Length()+1, default="")
;Array.Swap(i, j)
;Array.Clone()
;Array.getClass()

;method list end






;************************************************************************************
; 	AutoHotkey_L의 Object 객체를 멤버로 가지게 하여,
;	배열의 기본 기능을 Object의 기본 메소드로 위임하여 구현한 배열 클래스이다.
;	인덱스와 관련된 에러는 GetLastError()를 통해 알 수 있다.
;
;	[AHK version]
;		AHK_L 1.1.00.00 and later
;	 
;	[팩토리 메소드]
;		Array_New()
;		Array_ValueOf(str, delim=",")
;
; 	[메소드]
;		GetLastError()	
;		Length()
;		Set(idx, value)
;		Get(idx)
;		ToString(delim=",")
;		Add(value)
;		IndexOf(value)
;		Sort(asc=true)
;		Insert(idx, value)
;		Remove(idx)
;		BinarySearch(key, from=1, to=Length()+1)
;		Shuffle()
;		Push(value)
;		Pop()
;		Equals(other)
;		Fill(value, from=1, to=Length()+1)
;		CopyOf(from=1, to=Length()+1, default="")
;		Swap(i, j)
;		Clone()
;
;		이성진 추가 메소드
;		getClass()
;
;	[Object 위임 메소드]
;		_NewEnum()
;		MinIndex()
;		MaxIndex()
;		SetCapacity(MaxItems)
;		GetCapacity()
;
;	[TODO]
;		ValueOf()에서 Object를 받아들일 수 있도록 수정 - params* 이용
;		ToObject() 추가
;		Object.Insert(Value) 막기
;		Object.Insert(Index, Value1 [, Value2, ... ValueN ]) 막기
;		Object.Remove(IntKey, "") 막기
;		Object.Remove(FirstKey, LastKey) 막기
;
;
;
;
;************************************************************************************

; 팩토리 메소드
; class 키워드로 정의된 클래스를 함수 내부에서 사용하기 위해서는 global 키워드를 사용해야만 한다.
; 이를 보완하기 위해서 대신 함수를 사용하도록 한다. 
; @return 배열
Array_New() {
	global Array
	return new Array()
}

; 팩토리 메소드. 배열을 구분자로 구분된 문자열로부터 생성한다.
; @param str 구분자로 구분된 문자열
; @param delim 구분자. 기본값 ","
; @return 배열
Array_ValueOf(str, delim=",") {
	StringSplit, token, str, %delim%
	arr := Array_New()
	Loop, %token0%
		arr.mem[A_Index] := token%A_Index%
	return arr
}

class Array
{
	
	;*******************************************************************************
	; 생성자
	; 멤버는 반드시 생성자에서 "." 연산자로 정의한다. 
	;*******************************************************************************
	__new() {
		this.mem := Object()
		this.lastError := 0
	}
	
	;이성진 추가
	getClass() {
		return "Array"
	}

	;*******************************************************************************
	; public 함수
	;*******************************************************************************
	
	; 배열의 엘리먼트 개수를 반환한다.
	; @return 엘리먼트 개수
	Length() {
		len := this.mem.MaxIndex()
		return len == "" ? 0 : len
	}
		
	; 배열에 새 엘리먼트를 추가한다. 새 엘리먼트의 인덱스는 (이전배열의 길이 + 1)이 된다.
	; @param value 추가할 엘리먼트의 값
	Add(value) {
		this.mem[this.Length() + 1] := value
	}

	; 배열을 구분자로 구분된 문자열로 나타내어 반환한다.
	; @delim 구분자. 기본값 ","
	; @return 구분자로 구분된 문자열
	ToString(delim=",") {
		result := ""
		len := this.Length()
		Loop, % len
			result .= this.mem[A_Index] . delim
		If (len > 0)
			StringTrimRight, result, result, StrLen(delim)
		return result
	}
	
	; 배열의 특정 엘리먼트의 값을 설정한다. 성공하면 GetLastError()가 0을, 실패하면 1을 반환한다.
	; @param idx 대상 엘리먼트 인덱스. 단, [1,배열길이]여야만 한다.
	; @param value 새 엘리먼트 값
	; @return 새 엘리먼트 값
	Set(idx, value) {
		; 인덱스 값 유효성 테스트
		If (this.lastError := (!Array__CheckIndex(idx, 1, this.Length()) ? 1 : 0))
			return
		return this.mem[idx] := value
	}

	; 배열의 특정 엘리먼트 값을 반환한다. 성공하면 GetLastError()가 0을, 실패하면 1을 반환한다.
	; @param idx 대상 엘리먼트의 인덱스. 단, [1,배열길이]여야만 한다.
	; @return 엘리먼트 값
	Get(idx) {
		; 인덱스 값 유효성 테스트
		If (this.lastError := (!Array__CheckIndex(idx, 1, this.Length()) ? 1 : 0))
			return
		return this.mem[idx]
	}

	; 마지막으로 호출한 메소드의 실패여부를 알 수 있는 에러코드를 반환한다. 파라미터로 인덱스를 지정하는 메소드와 Pop()은 실행 후 이 메소드를 호출하여 성공여부를 알 수 있다.
	; @return 에러코드. 0이면 성공, 1이면 실패.
	GetLastError() {
		return this.lastError
	}
	
	; 배열 전체를 대상으로 특정 엘리먼트를 검색한다. 만일, 이 메소드가 자주 호출되며 배열을 정렬하여도 아무런 문제가 되지 않는다면, 이보다 훨씬 빠른 BinarySearch()를 사용하는 것이 좋다.
	; @param value 조회할 엘리먼트 값
	; @return 배열에 엘리먼트가 존재한다면 그 인덱스를 반환한다. 그렇지 않다면, 0을 반환한다.
	IndexOf(value) {
		for k,v in this.mem
			If (v == value)
				return k
		return 0
	}
	
	; 배열을 정렬한다.
	; @param asc 오름차순 여부. true이면 오름차순으로 false이면 내림차순으로 정렬한다. 기본값 true
	Sort(asc=true) {
		this._Sort(asc, 1, this.Length())
	}
	
	; 배열에 엘리먼트를 삽입한다. 성공하면 GetLastError()가 0을, 실패하면 1을 반환한다.
	; @param idx 삽입할 위치의 인덱스. 단, [1,배열길이+1]여야만 한다.
	; @param value 삽입할 엘리먼트의 값
	Insert(idx, value) {
		; 인덱스 값 유효성 테스트
		If (this.lastError := (!Array__CheckIndex(idx, 1, this.Length() + 1) ? 1 : 0))
			return
		this.mem.Insert(idx, value)
	}

	; 배열에서 특정 엘리먼트를 제거한다.
	; @param idx 대상 엘리먼트의 인덱스. 단, [1,배열길이]여야만 한다.
	; @return 제거된 엘리먼트의 값
	Remove(idx) {
		; 인덱스 값 유효성 테스트
		If (this.lastError := (!Array__CheckIndex(idx, 1, this.Length()) ? 1 : 0))
			return
		return this.mem.Remove(idx)
	}

	; 배열의 일정 범위를 대상으로 특정 엘리먼트를 바이너리 서치 알고리즘을 사용하여 검색한다. 대상 배열은 이 함수를 호출하기 전에 반드시 오름차순 정렬(Sort()사용)되어야 하며 정렬되지 않았다면 부정확한 결과가 반환된다. 또한 만일 값이 동일한 다수의 엘리먼트가 존재한다면, 이 중 어느 것이 반환될 지 보장되지 않는다. 범위 파라미터를 생략하면 전체 배열을 대상으로 검색한다. 만일 to 인덱스가 배열의 마지막 인덱스(exclusive)보다 크다면, 이 값으로 보정된다. 성공하면 GetLastError()가 0을, 실패하면 1을 반환한다.
	; @param key 검색할 엘리먼트 값
	; @param from 검색될 첫 엘리먼트의 인덱스, inclusive (이 값은 반드시 [1, 마지막 인덱스+1]이어야 한다.)
	; @param to 검색될 마지막 엘리먼트의 인덱스, exclusive (이 값은 반드시 [1, 마지막 인덱스+1]이며 "from" 인덱스보다 같거나 커야 한다.)
	; @return 배열에 검색 키가 존재한다면 그 인덱스를 반환한다. 그렇지 않으면 -(삽입위치)을 반환한다. 삽입위치는 이 위치에 Insert()를 사용하여 키값을 삽입하여도 범위 내의 엘리먼트들이 정렬 상태를 유지하는 위치를 말한다.
	BinarySearch(key, from="", to="") {
		; 인덱스 값을 지정하지 않았다면
		; [1,마지막 인덱스+1)로 설정
		last := this.Length() + 1
		from := Array__ValidateIndex(from, 1)
		to := Array__ValidateIndex(to, last)
		
		; 인덱스 값 유효성 테스트
		If (this.lastError := (!Array__CheckIndex(from, 1, last) || !Array__CheckIndex(to, 1, last) || from > to ? 1 : 0))
			return
		
		; 검색
		Loop {
			mid := Floor((from + to) / 2)
			If (from >= to)
				return -mid
			aVal := this.mem[mid]
			If (key == aVal)
				return mid
			Else IF (key < aVal)
				to := mid
			Else
				from := mid + 1
		}
	}
	
	; Add()와 동일한 작업을 수행한다. 단순히 스택처럼 동작함을 의미하기 위해서 존재한다.
	; @param value 추가할 엘리먼트의 값
	Push(value) {
		this.Add(value)
	}
	
	; 배열의 마지막 엘리먼트를 제거하고 그 값을 리턴한다. 성공하면 GetLastError()가 0을, 실패하면 1을 반환한다.
	; @return 마지막 엘리먼트 값
	Pop() {
		If (this.lastError := (this.Length() == 0 ? 1 : 0))
			return
		return this.mem.Remove()
	}
	
	; 배열의 동일성 테스트를 수행한다.
	; @param other 배열2
	; @return 동일한지 여부
	Equals(other) {
		If (this == other)
			return true
		If (!IsObject(other)
				; || this.__Class != other.__Class
				|| this.Length() != other.Length())
			return false
		; 엘리먼트 별 비교
		for idx,value in this.mem
			If (value != other.mem[idx])
				return false
		return true
	}

	; 배열의 특정 범위의 엘리먼트를 특정 값으로 채운다. 범위 파라미터를 생략하면 전체 엘리먼트를 대상으로 값을 채운다. 만일 to 인덱스가 배열의 마지막 인덱스(exclusive)보다 크다면, 우선 [from,마지막 인덱스(exclusive))의 엘리먼트가 지정된 값으로 채워진 뒤, (to-마지막 인덱스(exclusive))개의 지정된 값을 가지는 엘리먼트가 새로 추가된다. 성공하면 GetLastError()가 0을, 실패하면 1을 반환한다.
	; @param value 채울 값
	; @param from 값을 채울 첫 엘리먼트의 인덱스, inclusive (이 값은 반드시 [1, 마지막 인덱스+1]이어야 한다.)
	; @param to 값을 채울 마지막 엘리먼트의 인덱스, exclusive (이 값은 반드시 "from" 인덱스보다 같거나 커야 한다.)
	Fill(value, from="", to="") {
		; 인덱스 값을 지정하지 않았다면
		; [1,마지막 인덱스+1)로 설정
		last := this.Length() + 1
		from := Array__ValidateIndex(from, 1)
		to := Array__ValidateIndex(to, last)
		
		; 인덱스 값 유효성 테스트
		If (this.lastError := (!Array__CheckIndex(from, 1, last) || from > to ? 1 : 0))
			return
		
		; 채우기
		Loop, % to - from
			this.mem[from + A_Index - 1] := value
	}

	; 특정 배열의 특정 범위의 엘리먼트를 복사하여 새로운 배열을 생성한다. 범위 파라미터를 생략하면 전체 배열을 복사한다. 만일 to 인덱스가 배열의 마지막 인덱스(exclusive)보다 크다면, 넘어선 범위의 엘리먼트 값은 default 파라미터로 지정한 값으로 설정되며, 새 배열의 길이는 (to-from)이 된다. 성공하면 GetLastError()가 0을, 실패하면 1을 반환한다.
	; @param from 복사할 첫 엘리먼트의 인덱스, inclusive (이 값은 반드시 [1, 마지막 인덱스+1]이어야 한다.)
	; @param to 복사할 마지막 엘리먼트의 인덱스, exclusive (이 값은 반드시 "from" 인덱스보다 같거나 커야 한다.)
	; @param default to 인덱스가 마지막 인덱스(exclusive)보다 클 때, 새로 추가될 엘리먼트들의 기본값이다.
	; @return 새로운 배열
	CopyOf(from="", to="", default="") {
		; 인덱스 값을 지정하지 않았다면
		; [1,마지막 인덱스+1)로 설정
		last := this.Length() + 1
		from := Array__ValidateIndex(from, 1)
		to := Array__ValidateIndex(to, last)
		
		; 인덱스 값 유효성 테스트
		If (this.lastError := (!Array__CheckIndex(from, 1, last) || from > to ? 1 : 0))
			return
		
		; 새 배열 생성
		newArr := Array_New()
		Loop, % to - from
		{
			srcIdx := from + A_Index - 1
			newArr.mem[A_Index] := srcIdx < last ? this.mem[srcIdx] : default 
		}
		return newArr
	}

	; 배열의 i번째 엘리먼트와 j번째 엘리먼트를 스왑한다. 성공하면 GetLastError()가 0을, 실패하면 1을 반환한다.
	; @param i 인덱스
	; @param j 인덱스
	Swap(i, j) {
		; 인덱스 값 유효성 테스트
		len := this.Length()
		If (this.lastError := (!Array__CheckIndex(i, 1, len) || !Array__CheckIndex(j, 1, len) ? 1 : 0))
			return
		this._Swap(i, j)
	}

	; 특정 배열을 복제한 새로운 배열을 생성한다. shallow copy임.
	; @return 복제된 배열
	Clone() {
		; 빈 배열 생성
		cloned := Array_New()
		
		; shallow copy
		cloned.mem := this.mem.Clone()
			
		return cloned
	}
		
	; 배열의 엘리먼트들을 무작위로 섞는다.
	Shuffle() {
		Random,, %A_TickCount%
		len := this.Length()
		Loop, %len% {
			Random, a, 1, %len%
			Random, b, 1, %len%
			this._Swap(a, b)
		}
	}
		
	;*******************************************************************************
	; mem 멤버 위임 메소드
	;*******************************************************************************
	
	__Set(idx, value) {
		; "mem"이나 "lastError"의 경우, 명시적으로 처리하지 않으면
		; default behavior로 처리된다.
		If idx not in mem,lastError
			return this.Set(idx, value)
	}
	
	__Get(idx) {
		; "mem"이나 "lastError"의 경우, 명시적으로 처리하지 않으면
		; default behavior로 처리된다.
		If idx not in mem,lastError
			return this.Get(idx)
	}
	
	/* 이성진 임시 주석. for 문이 안돔.
	_NewEnum() {
		return this.mem._NewEnum()
	}
	*/
	
	MinIndex() {
		return this.mem.MinIndex()
	}
	
	MaxIndex() {
		return this.mem.MaxIndex()
	}
	
	SetCapacity(maxItems) {
		return this.mem.SetCapacity(maxItems)
	}
	
	GetCapacity() {
		return this.mem.GetCapacity()
	}

	;*******************************************************************************
	; private 함수
	; 오토핫키에서는 private 키워드를 지원하지 않으므로
	; _로 시작하는 이름을 가지도록 하여 구분한다.
	;*******************************************************************************
	
	; 배열의 [left,right] 엘리먼트를 대상으로 퀵소트를 수행한다.
	; @param asc 오름차순 여부
	; @param left 정렬할 엘리먼트의 시작 인덱스 (inclusive)
	; @param right 정렬할 엘리먼트의 끝 인덱스 (inclusive)
	_Sort(asc, left, right) {
		If (left < right) {
			pivot := this._Partition(asc, left, right)
			this._Sort(asc, left, pivot - 1)
			this._Sort(asc, pivot + 1, right)
		}
	}

	; left번째 엘리먼트를 피벗으로 하여, [left+1,right] 엘리먼트를 분할한다.
	; @param asc 오름차순 여부
	; @param left 정렬할 엘리먼트의 시작 인덱스 (inclusive)
	; @param right 정렬할 엘리먼트의 끝 인덱스 (inclusive)
	; @return 분할 후, 피벗의 인덱스
	_Partition(asc, left, right) {
		pivot := this.mem[left]
		i := left
		j := right + 1
		Loop {
			Loop {
				i++
				aVal := this.mem[i]
				If (i == right || (asc ? aVal >= pivot : aVal <= pivot))
					break
			}
			Loop {
				j--
				aVal := this.mem[j]
				If (j == left || (asc ? aVal <= pivot : aVal >= pivot))
					break
			}
			If (i >= j)
				break
			this._Swap(i, j)
		}
		this._Swap(left, j)
		return j
	}
	
	; 배열의 i번째 엘리먼트와 j번째 엘리먼트를 스왑한다.
	; @param i 인덱스
	; @param j 인덱스
	_Swap(i, j) {
		tmp := this.mem[i]
		this.mem[i] := this.mem[j]
		this.mem[j] := tmp
	}
}

;*******************************************************************************
; private static 메소드
; 오토핫키에서는 private static 키워드를 지원하지 않으므로
; _로 시작하는 이름을 가지는 함수로 정의하도록 한다.
;*******************************************************************************

; 인덱스가 유효하면 그대로, 아니면 디폴트 값을 반환한다.
; @param idx 인덱스
; @param default 디폴트 값
; @return 유효한 인덱스
Array__ValidateIndex(idx, default) {
	return idx != "" ? idx : default  
}

; 인덱스가 유효한지 체크한다.
; @param idx 인덱스
; @param from lower bound
; @param to upper bound
Array__CheckIndex(idx, from, to) {
	return Array__IsInteger(idx) && from <= idx && idx <= to
}

; 변수에 저장된 값이 정수인지 여부를 반환한다.
; @param var 대상변수
; @return 변수에 저장된 값이 정수인지 여부
Array__IsInteger(var) {
	If var is integer
		return true
	Else
		return false
}
