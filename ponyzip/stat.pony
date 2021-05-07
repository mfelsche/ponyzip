struct _ZipStat
  """
  Raw zip_stat_t struct

  struct zip_stat {
    zip_uint64_t valid;                 /* which fields have valid values */
    const char *name;                   /* name of the file */
    zip_uint64_t index;                 /* index within archive */
    zip_uint64_t size;                  /* size of file (uncompressed) */
    zip_uint64_t comp_size;             /* size of file (compressed) */
    time_t mtime;                       /* modification time */
    zip_uint32_t crc;                   /* crc of file data */
    zip_uint16_t comp_method;           /* compression method used */
    zip_uint16_t encryption_method;     /* encryption method used */
    zip_uint32_t flags;                 /* reserved for future use */
  };
  """
  let valid: U64 = 0
  let name: Pointer[U8] ref = Pointer[U8].create()
  let index: U64 = 0
  let size: U64 = 0
    """uncompressed size"""
  let comp_size: U64 = 0
    """compressed size"""
  let mtime: U64 = 0 // assuming a time_t is 64 bit
  let crc: U32 = 0
  let comp_method: U16 = 0
    """compression method used"""
  let encryption_method: U16 = 0
    """encryption method used"""
  let flags: U32 = 0

class ref ZipStat
  // TODO: make it val
  // TODO: implement Stringable
  let _archive: ZipArchive box

  let name: (String | None)
  let index: (U64 | None)
  let size: (U64 | None)
  let compressed_size: (U64 | None)
  let mtime: (U64 | None)
  let crc: (U32 | None)
  let compression_method: (CompressionMethod | None)
  let encryption_method: (EncryptionMethod | None)
  let flags: (U32 | None)

  new ref _create(archive: ZipArchive box, raw: _ZipStat) =>
    _archive = archive
    index =
      if (raw.valid or ZipStatIndex()) != 0 then
        raw.index
      end
    name =
      if (raw.valid or ZipStatName()) != 0 then
        String.copy_cstring(raw.name).clone()
      end
    size =
      if (raw.valid or ZipStatSize()) != 0 then
        raw.size
      end
    compressed_size =
      if (raw.valid or ZipStatCompSize()) != 0 then
        raw.comp_size
      end
    mtime =
      if (raw.valid or ZipStatMTime()) != 0 then
        raw.mtime
      end
    crc =
      if (raw.valid or ZipStatCrc()) != 0 then
        raw.crc
      end
    compression_method =
      if (raw.valid or ZipStatCompMethod()) != 0 then
        match raw.comp_method
        | CMDefault.value() => CMDefault
        | CMUncompressed.value() => CMUncompressed
        | CMShrunk.value() => CMShrunk
        | CMReduce1.value() => CMReduce1
        | CMReduce2.value() => CMReduce2
        | CMReduce3.value() => CMReduce3
        | CMReduce4.value() => CMReduce4
        | CMImplode.value() => CMImplode
        | CMDeflate.value() => CMDeflate
        | CMDeflate64.value() => CMDeflate64
        | CMPKWareImplode.value() => CMPKWareImplode
        | CMBZip2.value() => CMBZip2
        | CMLZMA.value() => CMLZMA
        | CMTerse.value() => CMTerse
        | CMLZ77.value() => CMLZ77
        | CMLZMA2.value() => CMLZMA2
        | CMXZ.value() => CMXZ
        | CMJPEG.value() => CMJPEG
        | CMWavPack.value() => CMWavPack
        | CMPPMD.value() => CMPPMD
        end
      end
    encryption_method =
      if (raw.valid or ZipStatEncryptionMethod()) != 0 then
        match raw.encryption_method
        | EMNone.value() => EMNone
        | EMTraditionalPKWARE.value() => EMTraditionalPKWARE
        | EMDES.value() => EMDES
        | EMRC2Old.value() => EMRC2Old
        | EM3DES168.value() => EM3DES168
        | EM3DES112.value() => EM3DES112
        | EMPkZipAES128.value() => EMPkZipAES128
        | EMPkZipAES192.value() => EMPkZipAES192
        | EMPkZipAES256.value() => EMPkZipAES256
        | EMRC2.value() => EMRC2
        | EMRC4.value() => EMRC4
        | EMAES128.value() => EMAES128
        | EMAES192.value() => EMAES192
        | EMAES256.value() => EMAES256
        | EMUnknown.value() => EMUnknown
        end
      end
    flags =
      if (raw.valid or ZipStatFlags()) != 0 then
        raw.flags
      end

  fun open(password: (String | None) = None): (ZipFile | ZipErrorT) =>
    """
    open the zip archive entry described by this stat instance
    """
    let pw = match encryption_method
    | None | EMNone =>
      // no need for a password
      None
    else
      password
    end
    try
      _archive.open_by_index(index as U64, pw)?
    else
      _archive.get_error()
    end



primitive CMDefault
  fun value(): U16 => -1
primitive CMUncompressed
  fun value(): U16 => 0
primitive CMShrunk
  """shrunk"""
  fun value(): U16 => 1
primitive CMReduce1
  """reduced with factor 1"""
  fun value(): U16 => 2
primitive CMReduce2
  """reduced with factor 2"""
  fun value(): U16 => 3
primitive CMReduce3
  """reduced with factor 3"""
  fun value(): U16 => 4
primitive CMReduce4
  """reduced with factor 4"""
  fun value(): U16 => 5
primitive CMImplode
  """imploded"""
  fun value(): U16 => 6
primitive CMDeflate
  fun value(): U16 => 8
primitive CMDeflate64
  fun value(): U16 => 9
primitive CMPKWareImplode
  fun value(): U16 => 10
primitive CMBZip2
  fun value(): U16 => 12
primitive CMLZMA
  fun value(): U16 => 14
primitive CMTerse
  fun value(): U16 => 18
primitive CMLZ77
  fun value(): U16 => 19
primitive CMLZMA2
  fun value(): U16 => 33
primitive CMXZ
  fun value(): U16 => 95
primitive CMJPEG
  fun value(): U16 => 96
primitive CMWavPack
  fun value(): U16 => 97
primitive CMPPMD
  fun value(): U16 => 98

type CompressionMethod is (
  CMDefault
  | CMUncompressed
  | CMShrunk
  | CMReduce1
  | CMReduce2
  | CMReduce3
  | CMReduce4
  | CMImplode
  | CMDeflate
  | CMDeflate64
  | CMPKWareImplode
  | CMBZip2
  | CMLZMA
  | CMTerse
  | CMLZ77
  | CMLZMA2
  | CMXZ
  | CMJPEG
  | CMWavPack
  | CMPPMD
)


primitive EMNone
  """not encrypted"""
  fun value(): U16 => 0
primitive EMTraditionalPKWARE
  """traditional PKWARE encryption"""
  fun value(): U16 => 1
primitive EMDES
  """DES encrypted"""
  fun value(): U16 => 0x6601
primitive EMRC2Old
  """RC2, version < 5.2"""
  fun value(): U16 => 0x6602
primitive EM3DES168
  fun value(): U16 => 0x6603
primitive EM3DES112
  fun value(): U16 => 0x6609
primitive EMPkZipAES128
  fun value(): U16 => 0x660e
primitive EMPkZipAES192
  fun value(): U16 => 0x660f
primitive EMPkZipAES256
  fun value(): U16 => 0x6610
primitive EMRC2
  """RC2, version >= 5.2"""
  fun value(): U16 => 0x6702
primitive EMRC4
  fun value(): U16 => 0x6801
primitive EMAES128
  """Winzip AES encryption"""
  fun value(): U16 => 0x0101
primitive EMAES192
  fun value(): U16 => 0x0102
primitive EMAES256
  fun value(): U16 => 0x0103
primitive EMUnknown
  """unknown algorithm"""
  fun value(): U16 => 0xffff

type EncryptionMethod is (
  EMNone
  | EMTraditionalPKWARE
  | EMDES
  | EMRC2Old
  | EM3DES168
  | EM3DES112
  | EMPkZipAES128
  | EMPkZipAES192
  | EMPkZipAES256
  | EMRC2
  | EMRC4
  | EMAES128
  | EMAES192
  | EMAES256
  | EMUnknown)




// flags for valid stat fields
primitive ZipStatName
  fun apply(): U64 => 0x1
  fun string(): String => "name"

primitive ZipStatIndex
  fun apply(): U64 => 0x2
  fun string(): String => "index"

primitive ZipStatSize
  fun apply(): U64 => 0x4
  fun string(): String => "size"

primitive ZipStatCompSize
  fun apply(): U64 => 0x8
  fun string(): String => "comp_size"

primitive ZipStatMTime
  fun apply(): U64 => 0x10
  fun string(): String => "name"

primitive ZipStatCrc
  fun apply(): U64 => 0x20
  fun string(): String => "crc"

primitive ZipStatCompMethod
  fun apply(): U64 => 0x40
  fun string(): String => "comp_method"

primitive ZipStatEncryptionMethod
  fun apply(): U64 => 0x80
  fun string(): String => "encryption_method"

primitive ZipStatFlags
  fun apply(): U64 => 0x100
  fun string(): String => "flags"

type ZipStatField is (
  ZipStatName
  | ZipStatIndex
  | ZipStatSize
  | ZipStatCompSize
  | ZipStatMTime
  | ZipStatCrc
  | ZipStatCompMethod
  | ZipStatEncryptionMethod
  | ZipStatFlags )

