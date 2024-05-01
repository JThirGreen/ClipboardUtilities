# Clipboard Utilities
# Context Menu
### Hot Keys
- `Alt` + `Shift` + `Space`  
Opens full context menu  
![image](https://github.com/JThirGreen/ClipboardUtilities/assets/35150682/c696500c-5585-4ab2-85c9-cab6bd30f792)


## Clipboard Manager
### Hot Keys
- `Alt` + `Shift` + `v`  
Opens clipboard context menu

- `Ctrl` + `Shift` + `x`  
Swaps content selected with content currently in clipboard

- `Ctrl` + `Shift` + `c`  
Clears clips from clip manager and copies selected content to it. If content is a supported delimited string, then it is parsed with each value stored as a separate clip item.

- `Ctrl` + `Shift` + `v`  
Activates clip manager tooltip and (while held) enables the following clip manager key actions:

| Key                    | Action
|------------------------|----------
| `v up`                 | Releasing `v` disables further actions.
|                        | If no other key action was used, then the native `Ctrl` + `Shift` + `v` command is triggered.
| `Up` / `Scroll Up`     | Selects the previous clip in the clip manager list.
| `Down` / `Scroll Down` | Selects the next clip in the clip manager list.
| `Enter` / `Left Click` | Pastes the currently selected clip.
| `Delete`               | Deletes the currently selected clip and selects the next clip. If there is no next clip, then the previous clip is selected instead.
| `Backspace`            | Deletes the previous clip in the clip manager list.
| `Left` / `Back`        | If selected clip is unchanged, then this selects and pastes the previous clip in the clip manager list.
|                        | If the selected clip has changed, then this instead functions like `Delete`.
| `Right` / `Forward`    | If selected clip is unchanged, then this selects and pastes the next clip in the clip manager list.
|                        | If the selected clip has changed, then this instead functions like `Enter` / `Left Click`.

## Text Transformations
### Case Transformations
| Case State   | _Text conTent_
|--------------|-----------------
| UPPERCASE    | _TEXT CONTENT_
| Title Case   | _Text Content_
| Capital case | _Text content_
| lowercase    | _text content_
| CamelCase    | _TextContent_

### Hot Keys
- `Ctrl` + `Shift` + `Scroll Up`  
`Ctrl` + `Shift` + `Scroll Down`  
Takes selected text and shifts it to the next higher case state. The currently selected case state is shown in the form of a tooltip.
  - `Enter` causes the currently selected case state to be applied to the selected text. If currently selected case state is unchanged for a small period of time, then it get auto-applied.
  - `Esc` cancels the transformation and prevents it from being auto-applied.
``` mermaid
flowchart LR
  A[lowercase]
  B["Captital case"]
  C["Title Case"]
  D[UPPERCASE]
  subgraph Scroll
    direction LR
    D -- Down --> C -- Down --> B -- Down --> A
    A -- Up --> B -- Up --> C -- Up --> D
  end
```

- `Ctrl` + `Shift` + `Scroll Tilt Right`  
`Ctrl` + `Shift` + `Scroll Tilt Left`  
Takes selected text and transforms it to/from camel case.
``` mermaid
flowchart LR
  A[CamelCase]
  B["camel case"]
  subgraph Camel["Scroll Tilt"]
    direction LR
    B -- Left --> A
    A -- Right --> B
  end
```

- `Alt` + `"` `'` `(` `)` `{` `}` `[` `]`  
Wrap selected text based on which supported wrapper key is pressed

| Key       | _Text Content_
|:---------:|-----------------
| `"`       | "_Text Content_"
| `'`       | '_Text Content_'
| `(` / `)` | (_Text Content_)
| `{` / `}` | {_Text Content_}
| `[` / `]` | [_Text Content_]

## XML Transformations
### Hot Keys
- `Alt` + `Shift` + `<`  
Escapes `<` and `>` to `&lt;` and `&gt;` respectively in selected text.

- `Alt` + `Shift` + `>`  
Unescapes `&lt;` and `&gt;` to `<` and `>` respectively in selected text.

- `Alt` + `Shift` + `e`  
Escapes `<` `>` `'` `"` `&` to `&lt;` `&gt;` `&apos;` `&quot;` `&amp;` respectively in selected text.

- `Alt` + `Shift` + `d`  
Unescapes `&lt;` `&gt;` `&apos;` `&quot;` `&amp;` to `<` `>` `'` `"` `&` respectively in selected text.

- `Alt` + `Shift` + `Delete`  
Wraps selected text in XML comment `<!-- Text Content -->`.

- `Alt` + `Shift` + `Insert`  
Unwraps first found XML comment in selected text.
