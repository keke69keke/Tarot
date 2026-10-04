#!/usr/bin/env python3
import sys
import os

# Try to use Objective-C bindings if available, otherwise use ctypes
try:
    import objc
    from Foundation import NSWorkspace, NSRunningApplication
    from ApplicationServices import (
        AXUIElementCreateApplication,
        AXUIElementCopyAttributeValue,
        AXUIElementCopyAttributeNames,
        kAXFocusedApplicationAttribute,
        kAXWindowsAttribute,
        kAXRoleAttribute,
        kAXTitleAttribute,
        kAXPositionAttribute,
        kAXSizeAttribute,
        kAXChildrenAttribute,
        kAXValueAttribute,
        kAXIdentifierAttribute,
        kAXDescriptionAttribute,
        kAXSubroleAttribute,
        kAXEnabledAttribute,
    )
    HAS_OBJC = True
except ImportError:
    HAS_OBJC = False
    print("Objective-C bindings not available")

if HAS_OBJC:
    workspace = NSWorkspace.sharedWorkspace()
    front_app = workspace.frontmostApplication()
    if not front_app:
        print("No frontmost application")
        sys.exit(1)
    
    pid = front_app.processIdentifier()
    print(f"Frontmost app: {front_app.localizedName()} (PID: {pid})")
    
    app_element = AXUIElementCreateApplication(pid)
    
    def dump_element(element, indent=0, max_depth=10):
        if indent > max_depth:
            return
        try:
            role = AXUIElementCopyAttributeValue(element, kAXRoleAttribute, None)
            role_str = str(role[1]) if role and role[0] else "Unknown"
            
            subrole = AXUIElementCopyAttributeValue(element, kAXSubroleAttribute, None)
            subrole_str = str(subrole[1]) if subrole and subrole[0] else ""
            
            title = AXUIElementCopyAttributeValue(element, kAXTitleAttribute, None)
            title_str = str(title[1]) if title and title[0] else ""
            
            identifier = AXUIElementCopyAttributeValue(element, kAXIdentifierAttribute, None)
            identifier_str = str(identifier[1]) if identifier and identifier[0] else ""
            
            desc = AXUIElementCopyAttributeValue(element, kAXDescriptionAttribute, None)
            desc_str = str(desc[1]) if desc and desc[0] else ""
            
            value = AXUIElementCopyAttributeValue(element, kAXValueAttribute, None)
            value_str = str(value[1]) if value and value[0] else ""
            
            pos = AXUIElementCopyAttributeValue(element, kAXPositionAttribute, None)
            size = AXUIElementCopyAttributeValue(element, kAXSizeAttribute, None)
            pos_str = str(pos[1]) if pos and pos[0] else ""
            size_str = str(size[1]) if size and size[0] else ""
            
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
                info += f' @{pos_str} {size_str}'
            
            print(info)
            
            children = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute, None)
            if children and children[0] and children[1]:
                for child in children[1]:
                    dump_element(child, indent + 1, max_depth)
        except Exception as e:
            print(f"{'  ' * indent}Error: {e}")
    
    dump_element(app_element, 0, 10)
