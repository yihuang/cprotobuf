#!/usr/bin/env python3
"""Test script to verify PyDust rewrite structure."""

import sys
import os

# Add current directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    import cprotobuf
    from cprotobuf import ProtoEntity, Field, encode_primitive, decode_primitive

    print("✓ Successfully imported cprotobuf module")
    print(f"  Version: {getattr(cprotobuf, '__version__', 'unknown')}")

    # Test basic Field creation
    print("\nTesting Field class:")
    field = Field('int32', 1)
    print(f"  Created Field: type={field.type}, index={field.index}")

    # Test ProtoEntity class definition
    print("\nTesting ProtoEntity metaclass:")

    class Person(ProtoEntity):
        id = Field('int32', 1)
        name = Field('string', 2)
        email = Field('string', 3, required=False)

    print(f"  Created Person class")
    print(f"  Fields: {[f.name for f in Person._fields]}")

    # Test instance creation
    person = Person(id=123, name="Test User")
    print(f"  Created Person instance: id={person.id}, name={person.name}")

    # Test todict method
    person_dict = person.todict()
    print(f"  todict(): {person_dict}")

    print("\n✓ All basic tests passed!")

except ImportError as e:
    print(f"✗ Import error: {e}")
    print("\nThis is expected since the native module isn't built yet.")
    print("To build the PyDust module, run:")
    print("  pip install -e .")

except Exception as e:
    print(f"✗ Error during test: {e}")
    import traceback
    traceback.print_exc()

print("\n" + "="*60)
print("PyDust rewrite structure summary:")
print("="*60)
print("1. Created Zig source files in src/ directory:")
print("   - main.zig: Module entry point")
print("   - types.zig: Type definitions and descriptors")
print("   - encoder.zig: Encoding logic")
print("   - decoder.zig: Decoding logic")
print("   - python.zig: Python bindings with PyDust")
print()
print("2. Updated Python interface:")
print("   - __init__.py: Fallback implementation")
print("   - Will import from _native module when built")
print()
print("3. Updated build configuration:")
print("   - pyproject.toml: PyDust build configuration")
print("   - setup.py: Backward compatibility")
print()
print("4. Next steps:")
print("   - Install PyDust: pip install pydust")
print("   - Build module: pip install -e .")
print("   - Run tests: python -m pytest test/")
print("   - Implement missing native methods")
print("="*60)