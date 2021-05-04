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
      try
        z.close()?
      else
        h.fail(z.get_error().string())
      end
    | let e: ZipOpenError => h.fail(e.string())
    end
