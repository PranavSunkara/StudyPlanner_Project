import 'package:flutter/material.dart';
import 'dart:math';
import 'package:signature/signature.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Top-level color picker dialog widget
class _ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  const _ColorPickerDialog(this.initialColor);
  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _color;
  @override
  void initState() {
    super.initState();
    _color = widget.initialColor;
  }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick a color'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: _color.red.toDouble(),
            min: 0,
            max: 255,
            label: 'R: ${_color.red}',
            activeColor: Colors.red,
            onChanged: (v) => setState(() => _color = _color.withRed(v.toInt())),
          ),
          Slider(
            value: _color.green.toDouble(),
            min: 0,
            max: 255,
            label: 'G: ${_color.green}',
            activeColor: Colors.green,
            onChanged: (v) => setState(() => _color = _color.withGreen(v.toInt())),
          ),
          Slider(
            value: _color.blue.toDouble(),
            min: 0,
            max: 255,
            label: 'B: ${_color.blue}',
            activeColor: Colors.blue,
            onChanged: (v) => setState(() => _color = _color.withBlue(v.toInt())),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(_color),
          child: const Text('Select'),
        ),
      ],
    );
  }
}

class BookPage extends StatefulWidget {
  const BookPage({super.key});

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  final TextEditingController _subjectController = TextEditingController();
  List<String> _books = [];
  Map<String, String> _bookContents = {};

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _books = prefs.getStringList('books') ?? [];
      final contents = prefs.getString('bookContents');
      if (contents != null) {
        _bookContents = Map<String, String>.from(
          (contents.isNotEmpty ? Map<String, dynamic>.from(Uri.splitQueryString(contents)) : {}),
        );
      }
    });
  }

  Future<void> _saveBooks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('books', _books);
    await prefs.setString('bookContents', Uri(queryParameters: _bookContents).query);
  }

  void _addBook() {
    if (_subjectController.text.trim().isEmpty) return;
    setState(() {
      _books.add(_subjectController.text.trim());
      _bookContents[_subjectController.text.trim()] = '';
      _subjectController.clear();
    });
    _saveBooks();
  }

  void _deleteBook(int index) {
    setState(() {
      _bookContents.remove(_books[index]);
      _books.removeAt(index);
    });
    _saveBooks();
  }

  void _openBook(BuildContext context, String bookName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookDetailPage(
          bookName: bookName,
          initialContent: _bookContents[bookName] ?? '',
          onSave: (content) {
            setState(() {
              _bookContents[bookName] = content;
            });
            _saveBooks();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Planner',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Books', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subjectController,
                      decoration: InputDecoration(
                        labelText: 'Subject Name',
                        prefixIcon: Icon(Icons.subject, color: Colors.blue[400]),
                        filled: true,
                        fillColor: Colors.blue[50],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _addBook,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Book'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      elevation: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Your Books:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[700])),
            const SizedBox(height: 14),
            Expanded(
              child: _books.isEmpty
                  ? Center(child: Text('No books yet!', style: TextStyle(color: Colors.blue[300], fontSize: 17, fontWeight: FontWeight.w500)))
                  : ListView.builder(
                      itemCount: _books.length,
                      itemBuilder: (context, index) {
                        final bookName = _books[index];
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.09), blurRadius: 8, offset: Offset(0, 2))],
                          ),
                          child: ListTile(
                            leading: Icon(Icons.menu_book, color: Colors.blue[400]),
                            title: Text(bookName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _deleteBook(index),
                              tooltip: 'Delete Book',
                            ),
                            onTap: () => _openBook(context, bookName),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            tileColor: Colors.blue[50],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookDetailPage extends StatefulWidget {
  final String bookName;
  final String initialContent;
  final ValueChanged<String> onSave;

  BookDetailPage({Key? key, required this.bookName, required this.initialContent, required this.onSave}) : super(key: key);

  @override
  _BookDetailPageState createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {

  double _customStrokeWidth = 2.0;
  Color _customColor = Colors.black87;
  List<_Stroke> _strokes = [];
  List<Offset?> _currentPoints = [];

  void _startStroke(Offset pos) {
    _currentPoints = [pos];
  }

  void _addPoint(Offset pos) {
    setState(() {
      _currentPoints.add(pos);
    });
  }

  void _endStroke() {
    if (_currentPoints.length > 1) {
      _strokes.add(_Stroke(
        List<Offset?>.from(_currentPoints),
        _customColor,
        _customStrokeWidth,
        _tools[_selectedTool]['opacity'] ?? 1.0,
      ));
    }
    _currentPoints = [];
    setState(() {});
  }

  void _clearBoard() {
    setState(() {
      _strokes.clear();
      _currentPoints.clear();
    });
  }
  late SignatureController _signatureController;
  int _selectedTool = 1; // 0: pencil, 1: pen, 2: marker, 3: eraser

  final List<Map<String, dynamic>> _tools = [
    {
      'icon': Icons.create,
      'label': 'Pencil',
      'color': Colors.black87,
      'strokeWidth': 1.2,
      'opacity': 1.0,
      'smooth': false,
    },
    {
      'icon': Icons.edit,
      'label': 'Pen',
      'color': Colors.blue[900],
      'strokeWidth': 2.8,
      'opacity': 1.0,
      'smooth': true,
    },
    {
      'icon': Icons.brush,
      'label': 'Marker',
      'color': Colors.blue[700]?.withOpacity(0.5) ?? Colors.blue,
      'strokeWidth': 7.0,
      'opacity': 0.5,
      'smooth': false,
    },
    {
      'icon': Icons.auto_fix_normal,
      'label': 'Eraser',
      'color': Colors.white,
      'strokeWidth': 16.0,
      'opacity': 1.0,
      'smooth': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penColor: _tools[_selectedTool]['color'],
      penStrokeWidth: _tools[_selectedTool]['strokeWidth'],
      exportBackgroundColor: Colors.blue[50],
    );
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Planner',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(widget.bookName, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            tooltip: 'Save',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Drawing saved!')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.white),
            tooltip: 'Clear',
            onPressed: _clearBoard,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_tools.length, (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ChoiceChip(
                        label: Row(
                          children: [
                            Icon(_tools[i]['icon'], size: 20, color: _selectedTool == i ? Colors.blue : Colors.grey),
                            const SizedBox(width: 6),
                            Text(_tools[i]['label'], style: TextStyle(fontWeight: FontWeight.w600, color: _selectedTool == i ? Colors.blue : Colors.grey)),
                          ],
                        ),
                        selected: _selectedTool == i,
                        onSelected: (selected) {
                          setState(() {
                            _selectedTool = i;
                            _customStrokeWidth = _tools[i]['strokeWidth'];
                            _customColor = _tools[i]['color'] is Color ? _tools[i]['color'] : Colors.black87;
                          });
                        },
                        selectedColor: Colors.blue[50],
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: _selectedTool == i ? 4 : 0,
                      ),
                    )),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Size:', style: TextStyle(fontWeight: FontWeight.w500)),
                      Slider(
                        value: _customStrokeWidth,
                        min: 1.0,
                        max: 20.0,
                        divisions: 19,
                        label: _customStrokeWidth.toStringAsFixed(1),
                        onChanged: (value) {
                          setState(() {
                            _customStrokeWidth = value;
                          });
                        },
                      ),
                      Text(_customStrokeWidth.toStringAsFixed(1)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Color:', style: TextStyle(fontWeight: FontWeight.w500)),
                      SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          Color picked = await showDialog(
                            context: context,
                            builder: (context) => _ColorPickerDialog(_customColor),
                          );
                          setState(() {
                            _customColor = picked;
                          });
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _customColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                onPanStart: (details) {
                  _startStroke(details.localPosition);
                },
                onPanUpdate: (details) {
                  _addPoint(details.localPosition);
                },
                onPanEnd: (details) {
                  _endStroke();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.13), blurRadius: 18, offset: Offset(0, 6))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: CustomPaint(
                      painter: _WhiteboardPainter(_strokes, _currentPoints, _selectedTool == 3),
                      child: Container(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _Stroke {
  final List<Offset?> points;
  final Color color;
  final double strokeWidth;
  final double opacity;
  _Stroke(this.points, this.color, this.strokeWidth, this.opacity);
}

class _WhiteboardPainter extends CustomPainter {
  final List<_Stroke> strokes;
  final List<Offset?> currentPoints;
  final bool isEraser;
  _WhiteboardPainter(this.strokes, this.currentPoints, this.isEraser);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color.withOpacity(stroke.opacity)
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..blendMode = isEraser && stroke.color == Colors.white ? BlendMode.clear : BlendMode.srcOver;
      for (int i = 0; i < stroke.points.length - 1; i++) {
        if (stroke.points[i] != null && stroke.points[i + 1] != null) {
          canvas.drawLine(stroke.points[i]!, stroke.points[i + 1]!, paint);
        }
      }
    }
    // Draw current stroke
    if (currentPoints.isNotEmpty) {
      final toolColor = isEraser ? Colors.white : Colors.black;
      final paint = Paint()
        ..color = toolColor
        ..strokeWidth = isEraser ? 16.0 : 2.0
        ..strokeCap = StrokeCap.round
        ..blendMode = isEraser ? BlendMode.clear : BlendMode.srcOver;
      for (int i = 0; i < currentPoints.length - 1; i++) {
        if (currentPoints[i] != null && currentPoints[i + 1] != null) {
          canvas.drawLine(currentPoints[i]!, currentPoints[i + 1]!, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Planner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
        primaryColor: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
        ),
        cardTheme: CardThemeData(
          color: Colors.blue[50],
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      home: const MyHomePage(title: 'Study Planner'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}


class StudyTask {
  String title;
  String description;
  DateTime dueDate;
  StudyTask({required this.title, required this.description, required this.dueDate});
}

class MatrixBackground extends StatefulWidget {
  const MatrixBackground({super.key});

  @override
  State<MatrixBackground> createState() => _MatrixBackgroundState();
}

class _MatrixColumn {
  double y;
  double speed;
  int length;
  List<String> chars;
  _MatrixColumn(this.y, this.speed, this.length, this.chars);
}

class _MatrixBackgroundState extends State<MatrixBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_MatrixColumn> _columns;
  final int _numColumns = 18;
  final Random _rand = Random();
  final List<String> _matrixChars = List.generate(30, (i) => String.fromCharCode(0x30A0 + i));

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _columns = List.generate(_numColumns, (i) => _randomColumn());
  }

  _MatrixColumn _randomColumn() {
    int len = 8 + _rand.nextInt(8);
    return _MatrixColumn(
      _rand.nextDouble(),
      0.2 + _rand.nextDouble() * 0.4,
      len,
      List.generate(len, (i) => _matrixChars[_rand.nextInt(_matrixChars.length)]),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _MatrixPainter(_columns, _controller.value, _rand, _matrixChars),
          size: MediaQuery.of(context).size,
        );
      },
    );
  }
}

class _MatrixPainter extends CustomPainter {
  final List<_MatrixColumn> columns;
  final double progress;
  final Random rand;
  final List<String> matrixChars;
  _MatrixPainter(this.columns, this.progress, this.rand, this.matrixChars);

  @override
  void paint(Canvas canvas, Size size) {
    final double colWidth = size.width / columns.length;
    final Paint paint = Paint();
    for (int i = 0; i < columns.length; i++) {
      final col = columns[i];
      double y = (col.y * size.height + progress * size.height * col.speed) % size.height;
      for (int j = 0; j < col.length; j++) {
        double charY = y - j * 22;
        if (charY < 0) charY += size.height;
    paint.color = j == 0
      ? Colors.blueAccent.withOpacity(0.9)
      : Colors.blue.withOpacity(0.7 - j * 0.04);
        TextPainter tp = TextPainter(
          text: TextSpan(
            text: col.chars[j],
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'monospace',
              color: paint.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(i * colWidth + colWidth / 4, charY));
      }
      // Occasionally randomize chars for animation
      if (rand.nextDouble() < 0.02) {
        col.chars[rand.nextInt(col.length)] = matrixChars[rand.nextInt(matrixChars.length)];
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MyHomePageState extends State<MyHomePage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _selectedDate;
  final List<StudyTask> _tasks = [];

  final _noteController = TextEditingController();
  final List<String> _notes = [];

  bool _showTasks = true;

  void _addTask() {
    if (_titleController.text.isEmpty || _selectedDate == null) return;
    setState(() {
      _tasks.add(StudyTask(
        title: _titleController.text,
        description: _descController.text,
        dueDate: _selectedDate!,
      ));
      _titleController.clear();
      _descController.clear();
      _selectedDate = null;
    });
  }

  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
  }

  void _addNote() {
    if (_noteController.text.isEmpty) return;
    setState(() {
      _notes.add(_noteController.text);
      _noteController.clear();
    });
  }

  void _deleteNote(int index) {
    setState(() {
      _notes.removeAt(index);
    });
  }

  void _switchToTasks() {
    setState(() {
      _showTasks = true;
    });
  }

  void _switchToNotes() {
    setState(() {
      _showTasks = false;
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Planner', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.book, color: Colors.white),
            tooltip: 'Book',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const BookPage()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          const MatrixBackground(),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.13), blurRadius: 18, offset: Offset(0, 6))],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text('Tasks', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700], fontSize: 18)),
                          Text('${_tasks.length}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Column(
                        children: [
                          Text('Notes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700], fontSize: 18)),
                          Text('${_notes.length}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
                Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.10), blurRadius: 12, offset: Offset(0, 4))],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _switchToTasks,
                          icon: const Icon(Icons.check_circle_outline, size: 20),
                          label: const Text('Tasks'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _showTasks ? Colors.blue : Colors.blue[100],
                            foregroundColor: _showTasks ? Colors.white : Colors.blue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: _showTasks ? 4 : 0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _switchToNotes,
                          icon: const Icon(Icons.sticky_note_2_outlined, size: 20),
                          label: const Text('Notes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !_showTasks ? Colors.blue : Colors.blue[100],
                            foregroundColor: !_showTasks ? Colors.white : Colors.blue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: !_showTasks ? 4 : 0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const BookPage()),
                            );
                          },
                          icon: const Icon(Icons.book, size: 20),
                          label: const Text('Book'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[100],
                            foregroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: SingleChildScrollView(
                    child: _showTasks
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Add Study Task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                              const SizedBox(height: 10),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.08), blurRadius: 8, offset: Offset(0, 2))],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextField(
                                      controller: _titleController,
                                      decoration: const InputDecoration(
                                        labelText: 'Task Title',
                                        prefixIcon: Icon(Icons.title, color: Colors.blue),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: _descController,
                                      decoration: const InputDecoration(
                                        labelText: 'Description',
                                        prefixIcon: Icon(Icons.description, color: Colors.blue),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today, color: Colors.blue[300], size: 20),
                                        const SizedBox(width: 6),
                                        Text(_selectedDate == null
                                            ? 'No date chosen'
                                            : 'Due: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                                          style: TextStyle(color: Colors.blue[700]),
                                        ),
                                        TextButton(
                                          onPressed: () => _pickDate(context),
                                          child: const Text('Pick Due Date'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: _addTask,
                                        icon: const Icon(Icons.add_task),
                                        label: const Text('Add Task'),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text('Tasks:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 200,
                                child: _tasks.isEmpty
                                    ? Center(child: Text('No tasks yet!', style: TextStyle(color: Colors.blue[300], fontSize: 16)))
                                    : ListView.builder(
                                        itemCount: _tasks.length,
                                        itemBuilder: (context, index) {
                                          final task = _tasks[index];
                                          return Container(
                                            margin: const EdgeInsets.symmetric(vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[50],
                                              borderRadius: BorderRadius.circular(14),
                                              boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.07), blurRadius: 6, offset: Offset(0, 2))],
                                            ),
                                            child: ListTile(
                                              leading: Icon(Icons.check_circle_outline, color: Colors.blue[400]),
                                              title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                              subtitle: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  if (task.description.isNotEmpty)
                                                    Text(task.description, style: TextStyle(color: Colors.blue[700])),
                                                  Text('Due: ${task.dueDate.toLocal().toString().split(' ')[0]}', style: TextStyle(color: Colors.blue[300], fontSize: 13)),
                                                ],
                                              ),
                                              trailing: IconButton(
                                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                                onPressed: () => _deleteTask(index),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Notes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                              const SizedBox(height: 10),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.08), blurRadius: 8, offset: Offset(0, 2))],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    TextField(
                                      controller: _noteController,
                                      decoration: const InputDecoration(
                                        labelText: 'Write a note',
                                        prefixIcon: Icon(Icons.note_alt, color: Colors.blue),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: _addNote,
                                        icon: const Icon(Icons.add_comment),
                                        label: const Text('Add Note'),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                height: 150,
                                child: _notes.isEmpty
                                    ? Center(child: Text('No notes yet!', style: TextStyle(color: Colors.blue[300], fontSize: 16)))
                                    : ListView.builder(
                                        itemCount: _notes.length,
                                        itemBuilder: (context, index) {
                                          return Container(
                                            margin: const EdgeInsets.symmetric(vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[50],
                                              borderRadius: BorderRadius.circular(14),
                                              boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.07), blurRadius: 6, offset: Offset(0, 2))],
                                            ),
                                            child: ListTile(
                                              leading: Icon(Icons.sticky_note_2_outlined, color: Colors.blue[400]),
                                              title: Text(_notes[index], style: const TextStyle(fontWeight: FontWeight.w500)),
                                              trailing: IconButton(
                                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                                onPressed: () => _deleteNote(index),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
