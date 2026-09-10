#!/usr/bin/env python3
import ctypes
import ctypes.util
import sys

if len(sys.argv) < 2:
    print("Usage: dump_hierarchy_ctypes.py <pid>")
    sys.exit(1)

pid = int(sys.argv[1])

# Load frameworks
app_services = ctypes.CDLL(ctypes.util.find_library('ApplicationServices'), use_errno=True)
foundation = ctypes.CDLL(ctypes.util.find_library('Foundation'), use_errno=True)

# AXUIElementRef is a pointer type
class AXUIElementRef(ctypes.c_void_p):
    pass

# CFTypeRef
CFTypeRef = ctypes.c_void_p
CFStringRef = ctypes.c_void_p
CFArrayRef = ctypes.c_void_p
CFDictionaryRef = ctypes.c_void_p
CFNumberRef = ctypes.c_void_p

# Boolean
Boolean = ctypes.c_bool

# Error code
AXError = ctypes.c_int

# AXUIElementCopyAttributeValue
AXUIElementCopyAttributeValue = app_services.AXUIElementCopyAttributeValue
AXUIElementCopyAttributeValue.restype = AXError
AXUIElementCopyAttributeValue.argtypes = [AXUIElementRef, CFStringRef, ctypes.POINTER(ctypes.c_void_p)]

# AXUIElementCreateApplication
AXUIElementCreateApplication = app_services.AXUIElementCreateApplication
AXUIElementCreateApplication.restype = AXUIElementRef
AXUIElementCreateApplication.argtypes = [ctypes.c_int32]

# Helper to create CFString
def make_cf_string(s):
    if isinstance(s, str):
        return foundation.CFStringCreateWithCString(None, s.encode('utf-8'), 0)
    return None

# Helper to convert CFString to Python string
def cf_string_to_str(cf_str):
    if not cf_str:
        return ""
    length = foundation.CFStringGetLength(cf_str)
    if length == 0:
        return ""
    max_len = length * 4
    buf = ctypes.create_string_buffer(max_len)
    foundation.CFStringGetCString(cf_str, buf, max_len, 0)
    return buf.value.decode('utf-8')

# Get CFString constants
kAXRoleAttribute = make_cf_string("AXRole")
kAXTitleAttribute = make_cf_string("AXTitle")
kAXIdentifierAttribute = make_cf_string("AXIdentifier")
kAXDescriptionAttribute = make_cf_string("AXDescription")
kAXValueAttribute = make_cf_string("AXValue")
kAXPositionAttribute = make_cf_string("AXPosition")
kAXSizeAttribute = make_cf_string("AXSize")
kAXChildrenAttribute = make_cf_string("AXChildren")
kAXSubroleAttribute = make_cf_string("AXSubrole")

print(f"Dumping accessibility hierarchy for PID: {pid}")
app_element = AXUIElementCreateApplication(pid)

def dump_element(element, indent=0, max_depth=10):
    if indent > max_depth or not element:
        return
    
    try:
        role_val = ctypes.c_void_p()
        err = AXUIElementCopyAttributeValue(element, kAXRoleAttribute, ctypes.byref(role_val))
        role_str = cf_string_to_str(role_val) if err == 0 and role_val else "Unknown"
        
        subrole_val = ctypes.c_void_p()
        AXUIElementCopyAttributeValue(element, kAXSubroleAttribute, ctypes.byref(subrole_val))
        subrole_str = cf_string_to_str(subrole_val) if subrole_val else ""
        
        title_val = ctypes.c_void_p()
        AXUIElementCopyAttributeValue(element, kAXTitleAttribute, ctypes.byref(title_val))
        title_str = cf_string_to_str(title_val) if title_val else ""
        
        identifier_val = ctypes.c_void_p()
        AXUIElementCopyAttributeValue(element, kAXIdentifierAttribute, ctypes.byref(identifier_val))
        identifier_str = cf_string_to_str(identifier_val) if identifier_val else ""
        
        desc_val = ctypes.c_void_p()
        AXUIElementCopyAttributeValue(element, kAXDescriptionAttribute, ctypes.byref(desc_val))
        desc_str = cf_string_to_str(desc_val) if desc_val else ""
        
        value_val = ctypes.c_void_p()
        AXUIElementCopyAttributeValue(element, kAXValueAttribute, ctypes.byref(value_val))
        value_str = cf_string_to_str(value_val) if value_val else ""
        
        pos_val = ctypes.c_void_p()
        AXUIElementCopyAttributeValue(element, kAXPositionAttribute, ctypes.byref(pos_val))
        pos_str = ""
        if pos_val:
            pos_val_obj = ctypes.cast(pos_val, ctypes.POINTER(ctypes.c_double * 2)).contents
            pos_str = f"{{x={pos_val_obj[0]:.1f}, y={pos_val_obj[1]:.1f}}}"
        
        size_val = ctypes.c_void_p()
        AXUIElementCopyAttributeValue(element, kAXSizeAttribute, ctypes.byref(size_val))
        size_str = ""
        if size_val:
            size_val_obj = ctypes.cast(size_val, ctypes.POINTER(ctypes.c_double * 2)).contents
            size_str = f"{{w={size_val_obj[0]:.1f}, h={size_val_obj[1]:.1f}}}"
        
        prefix = "  " * indent
        info = f"{prefix}{role_str}"
        if subrole_str:
            info += f" ({subrole_str})"
        if title_str:
            info += f' title="{title_str}"'
        if identifier_str:
            info += f' id="{identifier_str}"'
        if desc_str:
            info += f' desc="{desc_str}"'
        if value_str:
            info += f' value="{value_str}"'
        if pos_str and size_str:
            info += f' {pos_str} {size_str}'
        
        print(info)
        
        children_val = ctypes.c_void_p()
        err = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute, ctypes.byref(children_val))
        if err == 0 and children_val:
            foundation.CFArrayGetCount.restype = ctypes.c_long
            foundation.CFArrayGetCount.argtypes = [CFArrayRef]
            count = foundation.CFArrayGetCount(children_val)
            
            foundation.CFArrayGetValueAtIndex.restype = ctypes.c_void_p
            foundation.CFArrayGetValueAtIndex.argtypes = [CFArrayRef, ctypes.c_long]
            
            for i in range(min(count, 100)):  # Limit to 100 children
                child = foundation.CFArrayGetValueAtIndex(children_val, i)
                dump_element(child, indent + 1, max_depth)
    except Exception as e:
        print(f"{'  ' * indent}Error: {e}")

dump_element(app_element, 0, 10)
