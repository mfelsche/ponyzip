use "ponytest"
use "files"

actor Main is TestList

  new create(env: Env) =>
    PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    test(ZipOpenCloseTest)

class iso ZipOpenCloseTest is UnitTest

  fun name(): String => "zip/open_close"

  fun apply(h: TestHelper) ? =>
    let path = FilePath(h.env.root as AmbientAuth, "source.zip")?
    match Zip.open(path, OpenFlags + RDONLY)
    | let z: ZipArchive =>
      h.assert_eq[String](path.path, z.path())
      h.assert_eq[Bool](false, z.is_closed())
      h.assert_eq[USize](3, z.num_entries(true))
      h.assert_eq[USize](3, z.num_entries(false))

      let stat0 = z.stat_by_index(0)?
      h.assert_eq[String]("ponyzip/_test.pony", stat0.name as String)
      h.assert_eq[U64](0, stat0.index as U64)
      h.assert_eq[U64](135, stat0.size as U64)
      let zfile0 = z.open_by_index(stat0.index as U64)?
      let data0 = zfile0.read((stat0.size as U64).usize())?
      h.assert_eq[USize](135, data0.size())
      h.assert_eq[String]("""
      use "ponytest"

      actor Main is TestList

        new create(env: Env) =>
          PonyTest(env, this)

        fun tag tests(test: PonyTest) =>
          None
      """, String.from_array(consume data0))

      try
        z.close()?
      else
        h.fail(z.get_error().string())
      end
    | let e: ZipError => h.fail(e.string())
    end
