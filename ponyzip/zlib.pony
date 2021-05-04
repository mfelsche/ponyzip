use "lib:z"
use "format"
use "debug"
use "files"

// impossible to get the sizeof of a pony struct as of now
//use @inflateInit_[I32](stream: NullablePointer[ZStream], version: Pointer[U8] tag, zstream_size: USize)
use @compress2[I32](dest: Pointer[U8] tag, dest_len: Pointer[ULong] tag, source: Pointer[U8] tag, source_len: ULong, level: I32)
use @compressBound[ULong](input_bytes: ULong)
use @uncompress[I32](dest: Pointer[U8] tag, dest_len: Pointer[ULong] tag, source: Pointer[U8] tag, source_len: ULong)
use @zlibVersion[Pointer[U8] ref]()

/**
 *
struct z_stream_s {
    z_const Bytef *next_in;     /* next input byte */
    uInt     avail_in;  /* number of bytes available at next_in */
    uLong    total_in;  /* total number of input bytes read so far */

    Bytef    *next_out; /* next output byte will go here */
    uInt     avail_out; /* remaining free space at next_out */
    uLong    total_out; /* total number of bytes output so far */

    z_const char *msg;  /* last error message, NULL if no error */
    struct internal_state FAR *state; /* not visible by applications */

    alloc_func zalloc;  /* used to allocate the internal state */
    free_func  zfree;   /* used to free the internal state */
    voidpf     opaque;  /* private data object passed to zalloc and zfree */

    int     data_type;  /* best guess about the data type: binary or text
                           for deflate, or the decoding state for inflate */
    uLong   adler;      /* Adler-32 or CRC-32 value of the uncompressed data */
    uLong   reserved;   /* reserved for future use */
} z_stream;
*/

struct ZStream
  let next_in: Pointer[U8] tag // const unsigned char*
  var avail_in: U32   // unsigned int
  var total_in: ULong // unsigned long

  var next_out: Pointer[U8] tag // unsigned char*
  var avail_out: U32 // unsigned int
  var total_out: ULong // unsigned long

  var msg: Pointer[U8] tag = Pointer[U8] // last error message
  var internal_state: Pointer[None] tag = Pointer[None]

  // NULL here will make it use the system allocator
  var zalloc: Pointer[None] tag = Pointer[None] // function pointer to a custom allocation function
  var zfree:  Pointer[None] tag = Pointer[None] // function pointer to a custom free function

  var opaque: Pointer[None] tag = Pointer[None]

  var data_type: I32 = 0 // int
  var adler: ULong = 0 // unsigned long, adler-32 or crc-32 value of uncompressed data
  var reserved: ULong = 0 // unsigned long, reserved for future use

  new create() =>
  //new inflate(compressed: Array[U8] box, out: Array[U8] ref) =>
    next_in = Pointer[U8]
    avail_in = 0
    total_in = 0
    next_out = Pointer[U8]
    avail_out = 0
    total_out = 0


primitive ZCompressionLevel
  fun z_no_compression(): I32 => 0
  fun z_best_speed(): I32 => 1
  fun z_best_compression(): I32 => 9
  fun z_default_compression(): I32 => -1

primitive ZCheckReturn
  fun apply(r: I32): ZReturn =>
    match r
    | ZOk() => ZOk
    | ZStreamEnd() => ZStreamEnd
    | ZNeedDict() => ZNeedDict
    | ZErrno() => ZErrno
    | ZStreamError() => ZStreamError
    | ZDataError() => ZDataError
    | ZMemError() => ZMemError
    | ZBufError() => ZBufError
    | ZVersionError() => ZVersionError
    else
      ZUnknownError
    end

primitive ZOk is (Stringable & Equatable[ZReturn])
  fun apply(): I32 => 0
  fun string(): String iso^ =>
    "ZOk".string()
primitive ZStreamEnd is (Stringable & Equatable[ZReturn])
  fun apply(): I32 => 1
  fun string(): String iso^ =>
    "ZStreamEnd".string()
primitive ZNeedDict is (Stringable & Equatable[ZReturn])
  fun apply(): I32 => 2
  fun string(): String iso^ =>
    "ZNeedDict".string()
primitive ZErrno is (Stringable & Equatable[ZReturn])
  fun apply(): I32 => -1
  fun string(): String iso^ =>
    "ZErrno".string()
primitive ZStreamError is (Stringable & Equatable[ZReturn])
  fun apply(): I32 => -2
  fun string(): String iso^ =>
    "ZStreamError".string()
primitive ZDataError is (Stringable & Equatable[ZReturn])
  fun apply(): I32 => -3
  fun string(): String iso^ =>
    "ZDataError".string()
primitive ZMemError is (Stringable & Equatable[ZReturn])
  fun apply(): I32 => -4
  fun string(): String iso^ =>
    "ZMemError".string()
primitive ZBufError is (Stringable & Equatable[ZReturn])
  fun apply(): I32 => -5
  fun string(): String iso^ =>
    "ZBufError".string()
primitive ZVersionError is (Stringable & Equatable[ZReturn])
  fun apply(): I32 => -6
  fun string(): String iso^ =>
    "ZVersionError".string()
primitive ZUnknownError is (Stringable & Equatable[ZReturn])
  fun apply(): I32 => 42 // chose some unused error number
  fun string(): String iso^ =>
    "ZUnknown".string()


type ZReturn is (ZOk | ZError)
type ZError is (ZStreamEnd | ZNeedDict | ZErrno | ZStreamError | ZDataError | ZMemError | ZStreamError | ZDataError | ZMemError | ZBufError | ZVersionError | ZUnknownError)



primitive ZLib

  fun z_binary(): I32 => 0
  fun z_text(): I32 => 1
  fun z_unknown(): I32 => 2

  fun z_default_compression(): I32 => -1

  fun version(): String iso^ =>
    recover
      let raw_version: Pointer[U8] ref = @zlibVersion()
      String.from_cstring(raw_version)
    end

  fun compress_bound(input_len: USize): USize =>
    """
    returns the maximum number of bytes needed when compressing `input_len` bytes.
    """
    @compressBound(input_len.ulong()).usize()

  fun compress(data: Array[U8] box, level: I32 = ZCompressionLevel.z_default_compression()): (Array[U8] iso^ | ZError) =>
    """
    Will allocate a new Array to write compressed data to and return that.
    """
    let output: Array[U8] iso = recover Array[U8].create(0) end
    output.undefined[U8](compress_bound(data.size()))
    match compress_raw(data, consume output, level)
    | (ZOk, let out: Array[U8] iso) => consume out
    | (let e: ZError, _) => e
    else
      ZUnknownError
    end

  fun compress_raw(data: Array[U8] box, output: Array[U8] iso, level: I32 = ZCompressionLevel.z_default_compression()): (ZReturn, Array[U8] iso^) =>
    """
    This will actually write the compressed data into the contents of the given output array.
    returns number of bytes actually written.
    """
    var size: ULong = output.size().ulong()
    let retval = @compress2(output.cpointer(), addressof size, data.cpointer(), data.size().ulong(), level)
    let zreturn = ZCheckReturn(retval)
    match zreturn
    | ZOk =>
      output.trim_in_place(0, size.usize())
    end
    (zreturn, consume output)

  fun uncompress(data: Array[U8] box, output_len: USize = 4096): (Array[U8] iso^ | ZError) =>
    let output = recover Array[U8].create(0) end
    var dest_len = output_len.ulong()
    output.undefined[U8](dest_len.usize())

    var zreturn: ZReturn = ZBufError

    while zreturn == ZBufError do

      zreturn = ZCheckReturn(@uncompress(output.cpointer(), addressof dest_len, data.cpointer(), data.size().ulong()))
      match zreturn
      | ZBufError =>
        // not enough room in output buffer
        // grow output buffer and retry
        dest_len = dest_len * 2
        output.undefined[U8](dest_len.usize())
      end

    end
    match zreturn
    | ZOk =>
      output.trim_in_place(0, dest_len.usize())
      return output
    | let e: ZError =>
      return e
    else
      ZUnknownError
    end
/**
actor Main
  new create(env: Env) =>
    let raw_version = @zlibVersion[Pointer[U8] ref]()
    let version = String.from_cstring(raw_version)
    env.out.print("zlib: " + version)
    try
      let p = env.args(1)?
      let fp = FilePath(env.root as AmbientAuth, p)?
      match OpenFile(fp)
      | let f: File =>
        let content = f.read(f.size())
        if Path.ext(fp.path) == "zip" then
          match ZLib.uncompress(consume content)
          | let uc: Array[U8] iso =>
            let y: Array[U8] val = consume uc
            env.out.print(String.from_array(y))
          | let uze: ZError =>
            env.err.print("Error uncompress: " + uze.string())
          end
        else
          let size = content.size()
          match ZLib.compress(consume content)
          | let uc: Array[U8] iso =>
            env.out.write(consume uc)
            //env.out.print("compressed from " + size.string() + " to " + uc.size().string() + " bytes.")
          | let uze: ZError =>
            env.err.print("Error compress: " + uze.string())
          end
        end
      end
    end

  fun print_hex(d: Array[U8] box, out: OutStream) =>
    out.write("0x")
    for x in d.values() do
      out.write(Format.int[U8](x where fmt = FormatHexBare))
    end
    out.write("\n")
*/
