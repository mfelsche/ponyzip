
use @zip_fclose[I32](file: Pointer[_ZipFile] tag)
use @zip_fread[I64](file: Pointer[_ZipFile] tag, buf: Pointer[U8] tag, nbytes: U64)
use @zip_fseek[I8](file: Pointer[_ZipFile] tag, offset: I64, whence: I32)
use @zip_ftell[I64](file: Pointer[_ZipFile] tag)

primitive _ZipFile

class ref ZipFile
  var _inner: Pointer[_ZipFile] tag

  new ref _create(inner: Pointer[_ZipFile] tag) =>
    _inner = inner

  fun ref read(num_bytes: USize): Array[U8] iso^ ? =>
    """
    Read data at the current possition
    """
    let data = recover
      let tmp = Array[U8].create(0)
      tmp.undefined[U8](num_bytes)
      tmp
    end
    match @zip_fread(_inner, data.cpointer(), num_bytes.u64())
    | -1 => error
    | let bytes_read: I64 =>
      data.truncate(bytes_read.usize())
    end
    consume data

  fun position(): USize ? =>
    """
    Return the current cursor position in the file.
    """
    let pos = @zip_ftell(_inner)
    if pos == -1 then
      error
    else
      pos.usize()
    end

  fun ref _seek(offset: I64, whence: Whence) ? =>
    if @zip_fseek(_inner, offset, whence()) != 0 then
      error
    end


  fun ref seek_start(offset: USize) ? =>
    """
    Set the cursor position relative to the start of the file.
    """
    //if path.caps(FileSeek) then
      _seek(offset.i64(), SeekStart)?
    //end

  fun ref seek_end(offset: USize) ? =>
    """
    Set the cursor position relative to the end of the file.
    """
    //if path.caps(FileSeek) then
      _seek(-offset.i64(), SeekEnd)?
    //end

  fun ref seek(offset: ISize) ? =>
    """
    Move the cursor position by `offset` from the current position.
    """
    //if path.caps(FileSeek) then
      _seek(offset.i64(), SeekCurrent)?
    //end

  fun ref close(): (ZipError | None) =>
    match ZipErrors.from_error_code(@zip_fclose(_inner))
    | Ok =>
      // set the inner pointer to NULL
      _inner = Pointer[_ZipFile].create()
      None
    | let e: ZipError =>
      e
    end

  fun is_closed(): Bool =>
    _inner.is_null()

primitive SeekCurrent
  fun apply(): I32 => 1
primitive SeekStart
  fun apply(): I32 => 0
primitive SeekEnd
  fun apply(): I32 => 2

type Whence is (SeekCurrent | SeekStart | SeekEnd)

