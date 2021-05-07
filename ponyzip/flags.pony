use "collections"

//// open flags
primitive CREATE
  """Create the archive if it does not exist."""
  fun value(): U32 => 1

primitive EXCL
  """Error is archive already exists"""
  fun value(): U32 => 2

primitive CHECKCONS
  """Perform additional stricter consistency checks on the archive, and error if they fail"""
  fun value(): U32 => 4

primitive TRUNCATE
  """If archive exists, ignore its current contents. In other words, handle it the same way as an empty archive."""
  fun value(): U32 => 8

primitive RDONLY
  """Open archive in read-only mode."""
  fun value(): U32 => 16


type OpenFlags is Flags[(CREATE | EXCL | CHECKCONS | TRUNCATE | RDONLY), U32]

primitive UNCHANGED
  """Use original data, ignore changes"""
  fun value(): U32 => 8

