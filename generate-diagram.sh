#!/bin/bash

# AWS Architecture Diagram Generator
# Installs dependencies and generates professional diagrams

set -e

echo "🎨 AWS Architecture Diagram Generator"
echo "===================================="

# Check if matplotlib is installed
if ! python3 -c "import matplotlib" 2>/dev/null; then
    echo "📦 Installing matplotlib..."
    
    # Try different installation methods
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -qq
        sudo apt-get install -y python3-matplotlib python3-numpy
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y python3-matplotlib python3-numpy
    elif command -v pip3 >/dev/null 2>&1; then
        pip3 install matplotlib numpy
    else
        echo "❌ Could not install matplotlib. Please install manually:"
        echo "   Ubuntu/Debian: sudo apt-get install python3-matplotlib"
        echo "   RHEL/CentOS: sudo yum install python3-matplotlib"
        echo "   pip: pip3 install matplotlib"
        exit 1
    fi
fi

echo "✅ Dependencies installed"

# Generate professional diagram
echo "🎯 Generating professional architecture diagram..."
if python3 professional-architecture-diagram.py; then
    echo "✅ Professional diagrams generated:"
    echo "   - aws-architecture-professional.png (300 DPI)"
    echo "   - aws-architecture-professional.pdf (vector)"
else
    echo "⚠️  Graphical diagram generation failed, but text diagram is available:"
    echo "   - architecture-diagram.md (detailed text diagram)"
fi

# Generate simple diagram as fallback
echo "🎯 Generating simple architecture diagram..."
if python3 architecture-diagram.py 2>/dev/null; then
    echo "✅ Simple diagrams generated:"
    echo "   - architecture-diagram.png"
    echo "   - architecture-diagram.svg"
fi

echo ""
echo "📋 Available Architecture Documentation:"
echo "   - architecture-diagram.md (comprehensive text diagram)"
echo "   - README.md (full project documentation)"

if [ -f "aws-architecture-professional.png" ]; then
    echo "   - aws-architecture-professional.png (presentation ready)"
    echo "   - aws-architecture-professional.pdf (vector format)"
fi

echo ""
echo "🚀 Ready for presentations and documentation!"
echo "   Use the PNG files for slides and the PDF for high-quality prints."