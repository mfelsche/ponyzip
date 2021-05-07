use @zip_error_code_zip[I32](err: Pointer[_ZipErrorT] tag)
use @zip_error_code_system[I32](err: Pointer[_ZipErrorT] tag)
use @zip_error_system_type[I32](err: Pointer[_ZipErrorT] tag)
use @zip_error_strerror[Pointer[U8] ref](err: Pointer[_ZipErrorT] tag)

class Errno
  let _errno: I32

  new _create(errno': I32) =>
    _errno = errno'

  fun errno(): I32 =>
    _errno

type ZipSystemError is (Errno | ZReturn)
  """Either a system errno or a libz error"""

primitive _ZipErrorT
class ZipErrorT
  """Zip error - wrapping zip_error_t"""
  let _inner: Pointer[_ZipErrorT] tag

  new _create(inner: Pointer[_ZipErrorT] tag) =>
    _inner = inner

  fun zip_error(): ZipResult =>
    ZipErrors.from_error_code(@zip_error_code_zip(_inner))

  fun system_error(): (ZipSystemError | None) =>
    match @zip_error_system_type(_inner)
    | 0 => None
    | 1 => Errno._create(@zip_error_code_system(_inner))
    | 2 => ZCheckReturn(@zip_error_code_system(_inner))
    end

  fun system_type(): I32 =>
    @zip_error_system_type(_inner)

  fun string(): String iso^ =>
    recover
      let raw = @zip_error_strerror(_inner)
      String.copy_cstring(raw)
    end

////////////////////////
// ZIP Errors
////////////////////////
primitive Ok
  fun apply(): I32 => 0
  fun string(): String =>
    "No error"

primitive MultidiskNotSupported
  fun apply(): I32 => 1
  fun string(): String =>
    "Multi-disk zip archives not supported"

primitive RenameFailed
  fun apply(): I32 => 2
  fun string(): String =>
    "Renaming temproary file failed"

// TODO: continue and add all 33 errors

primitive ArchiveExists
  fun apply(): I32 => 10
  fun string(): String =>
    "File already exists"

primitive ArchiveInconsistencies
  fun apply(): I32 => 21
  fun string(): String =>
    "Zip archive inconsistent"

primitive InvalidArgument
  fun apply(): I32 => 18
  fun string(): String =>
    "Invalid Argument"

primitive MallocFailure
  fun apply(): I32 => 14
  fun string(): String =>
    "Malloc failure"

primitive NoSuchFile
  fun apply(): I32 => 9
  fun string(): String =>
    "No such file"

primitive NoZipArchive
  fun apply(): I32 => 19
  fun string(): String =>
    "Not a zip archive"

primitive OpenFailed
  fun apply(): I32 => 11
  fun string(): String =>
    "Can't open file"

primitive ReadError
  fun apply(): I32 => 5
  fun string(): String =>
    "Read Error"

primitive SeekError
  fun apply(): I32 => 4
  fun string(): String =>
    "Seek Error"

class UnknownError
  let _err: I32

  new create(err: I32) =>
    _err = err

  fun apply(): I32 => _err

  fun string(): String =>
    "Unknown Error " + _err.string()

// TODO: add all errors
type ZipError is (
  ArchiveExists
  | ArchiveInconsistencies
  | InvalidArgument
  | MallocFailure
  | NoSuchFile
  | NoZipArchive
  | OpenFailed
  | ReadError
  | SeekError
  | UnknownError)
type ZipResult is (ZipError | Ok)

primitive ZipErrors
  fun from_error_code(err: I32): ZipResult =>
    match err
    | Ok() => Ok // all is good
    | ArchiveExists() => ArchiveExists
    | ArchiveInconsistencies() => ArchiveInconsistencies
    | InvalidArgument() => InvalidArgument
    | MallocFailure() => MallocFailure
    | NoSuchFile() => NoSuchFile
    | NoZipArchive() => NoZipArchive
    | OpenFailed() => OpenFailed
    | ReadError() => ReadError
    | SeekError() => SeekError
    else
      UnknownError(err)
    end

