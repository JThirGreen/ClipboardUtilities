#Requires AutoHotkey v2.0

/**
 * Extends upon {@link Array} with support for parsing multi-dimensional content as a flattened 1-dimensional array
 * @template T
 * @extends {Array}
 */
class NestedArray extends Array {

	/**
	 * The flattened version of the array.
	 * @template T
	 * @type {Array<T>}
	 */
	Items {
		get {
			/** @type {Array<T>} */
			flattened := ParseNestedArray(this)
			return flattened

			/**
			 * @param {Array<T>} arr
			 * @returns {Array<T>} Flattened version of array
			 */
			ParseNestedArray(arr) {
				items := []
				if (Type(arr) = Type(this)) {
					arr := arr.AsArray()
				}

				length := 0
				for item in arr {
					if (item != this) {
						if (item is Array) {
							items.Push(ParseNestedArray(item)*)
						}
						else {
							items.Push(item)
						}
					}
				}
				return items
			}
		}
	}

	/**
	 * The flattened length of the array.
	 * @type {Integer}
	 */
	TotalLength {
		get {
			return ParseNestedArray(this)

			/**
			 * @param {Array<T>} arr
			 * @returns {Integer} Flattened length of array
			 */
			ParseNestedArray(arr) {
				if (Type(arr) = Type(this)) {
					arr := arr.AsArray()
				}

				length := 0
				for item in arr {
					if (item != this) {
						length += (item is Array) ? ParseNestedArray(item) : 1
					}
				}
				return length
			}
		}
	}

	__Enum(NumberOfVars) {
		i := 1
		EnumItems(&item) {
			if (i > this.Length) {
				return false
			}
			item := this[i++]
			return true
		}
		EnumIndexAndItems(&index, &item) {
			index := i
			return EnumItems(&item)
		}
		EnumItemsFlattened(&index, &item, &array) {
			index := i
			if (i > this.TotalLength) {
				return false
			}
			item := this.Get(i++, , &array)
			return true
		}
		return (NumberOfVars = 1) ? EnumItems : EnumIndexAndItems
	}

	/**
	 * Delete the value of the array element so that the index does not contain a value.
	 * @param {Number} Index
	 * @returns {Any} Deleted value
	 */
	Delete(Index) {
		val := this[Index]
		this[Index] := ""
		return val
	}

	/**
	 * Returns the value at a given flattened array index, or a default value.
	 * @template T
	 * @param {Number} Index
	 * @param {T} Default
	 * @param {VarRef<T>} itemArray
	 */
	Get(Index, Default?, &itemArray?) {
		i := 0
		if (ParseNestedArray(this, Index, &i, &foundItem, &itemArray)) {
			return foundItem
		}

		defaultValue := ""
		if (IsSet(Default)) {
			defaultValue := Default
		}
		else if (this.HasProp("Default")) {
			defaultValue := this.Default
		}
		return defaultValue

		ParseNestedArray(arr, outerIndex, &outerOffset, &foundItem, &itemArray?) {
			Loop arr.Length {
				item := arr[A_Index]
				if (item is Array) {
					if (ParseNestedArray(item, outerIndex, &outerOffset, &foundItem, &itemArray)) {
						return true
					}
				}
				else {
					outerOffset++
					if (outerIndex = outerOffset) {
						foundItem := item
						if (IsSetRef(&itemArray)) {
							itemArray := arr
						}
						return true
					}
				}
			}
			return false
		}
	}

	/**
	 * If Index is valid and there is a value at that position, it returns true, otherwise it returns false.
	 * @param {Number} Index
	 */
	Has(Index) {
		return (IsInteger(Index) && Index > 0 && Index <= this.TotalLength && this.Get(Index, "") != "")
	}

	/**
	 * Insert one or more values to the given position.
	 * @param {Number} Index
	 * @param {Array<T>} Value
	 */
	InsertAt(Index, Value*) {
		relArray := this.GetRelativeArrayAndIndex(Index)
		relArray.Array.InsertAt(relArray.Index, Value)
	}

	/**
	 * Replace one or more values to the given position.
	 * @param {Number} Index
	 * @param {Array<T>} Value
	 */
	ReplaceAt(Index, Value*) {
		for idx, val in Value {
			valIdx := Index + idx
			relArray := this.GetRelativeArrayAndIndex(Index)
			relArray.Array[relArray.Index] := val
		}
	}

	/**
	 * Delete and return the last non-array element regardless of String()).
	 * @returns {T}
	 */
	PopItem() {
		item
		if (!this.Length) {
			return
		}
		else if (this[-1] is Array) {
			parentArray := this[-1]
			if (!parentArray.Length) {
				this.Pop()
				if (this.Length) {
					return this.PopItem()
				}
				return
			}
			else if (Type(parentArray) = Type(this)) {
				item := parentArray.PopItem()
			}
			else {
				item := parentArray.Pop()
			}
			if (!parentArray.Length) {
				this.Pop()
			}
			return item
		}
		else {
			return this.Pop()
		}
	}

	/**
	 * Remove one or more values started from the given position.
	 * @param {Number} Index
	 * @param {Number} Length
	 */
	RemoveAt(Index, Length?) {
		if (IsSet(Length)) {
			toRemove := Length
			removed := 0
			needCleaning := false
			while (toRemove > 0) {
				relativeDetails := this.GetRelativeArrayAndIndex((Index - 1) + toRemove)
				startIndex := 1 + relativeDetails.Index - toRemove
				if (startIndex < 1) {
					removed := relativeDetails.Index
					relativeDetails.Array.RemoveAt(1, removed)
				}
				else {
					removed := toRemove
					relativeDetails.Array.RemoveAt(startIndex, toRemove)
				}
				needCleaning := (needCleaning || !relativeDetails.Array.Length)
				toRemove -= removed
			}
			if (needCleaning) {
				this.Clean()
			}
		}
		else {
			super.RemoveAt(Index)
		}
	}

	/**
	 * Parse content and delete any empty arrays
	 */
	Clean() {
		CleanNestedArray(this)

		/**
		 * @param {Array} arr
		 */
		CleanNestedArray(arr) {
			Loop arr.Length {
				if (arr.Length < A_Index) {
					return
				}
			
				item := arr[A_Index]
				if (item is Array) {
					if (item.Length > 0){
						CleanNestedArray(item)
					}

					if (item.Length = 0) {
						arr.RemoveAt(A_Index)
						if (arr.Length < A_Index) {
							return
						}
						A_Index--
					}
				}
			}
		}
	}

	/**
	 * Determines and returns absolute coordinates of element based on its flattend array index
	 * @param {Integer} Index Flattened array index
	 * @returns {Array<Integer>}
	 */
	GetCoordsFromIndex(Index) {
		i := 0
		if (ParseNestedArray(this, Index, &i, &coords)) {
			return coords
		}

		return []

		ParseNestedArray(arr, outerIndex, &outerOffset, &coords) {
			coord := 0
			Loop arr.Length {
				coord++
				item := arr[A_Index]
				if (item is Array) {
					if (ParseNestedArray(item, outerIndex, &outerOffset, &innerCoords)) {
						coords := [coord, innerCoords*]
						return true
					}
				}
				else {
					outerOffset++
					if (outerIndex = outerOffset) {
						coords := [coord]
						return true
					}
				}
			}
			return false
		}
	}

	/**
	 * Finds element based on flattened index and returns its parent array along with some other relevant information
	 * @param {Integer} Index Flattened array index
	 * @returns {RelativeArray}
	 */
	GetRelativeArrayAndIndex(Index) {
		coords := this.GetCoordsFromIndex(Index)
		parentArray := this

		indexAt := 0
		for coord in coords {
			indexAt := coord
			item := parentArray[indexAt]
			if (item is Array) {
				parentArray := item
			}
		}
		return {
			Array: parentArray,
			Index: indexAt,
			Coords: coords,
			IsLast: (indexAt = parentArray.Length)
		}
	}

	/**
	 * Return an {@link Array} only copy of this {@link NestedArray}
	 * @returns {Array<T>}
	 */
	AsArray() {
		cloneArray := []
		Loop super.Length {
			item := super[A_Index]
			if (item != this) {
				cloneArray.Push((Type(item) = Type(this)) ? item.AsArray() : item)
			}
		}
		return cloneArray
	}
}

/**
 * @typedef {{
 *     Array: Array<T>,
 *     Index: Integer,
 *     Coords: Array,
 *     IsLast: true|false,
 * }} RelativeArray
 */