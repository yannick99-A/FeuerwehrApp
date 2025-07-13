import SwiftUI
import PhotosUI
import PencilKit

struct NotizenView: View {
    @State private var notizText: String = ""
    @State private var savedNotes: [Note] = []
    @State private var selectedImages: [UIImage] = []
    @State private var showFullScreenImage: UIImage? = nil
    @State private var editingNote: Note? = nil
    @State private var showCamera = false
    @State private var showGallery = false
    @State private var isDrawingMode = false
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    @State private var isDrawingFullscreen = false
    @State private var showDeleteAlert = false
    @State private var noteToDelete: Note? = nil
    @State private var isKeyboardVisible = false
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Bildbereich
                    if !selectedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(selectedImages, id: \.self) { image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 200, height: 250)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white, lineWidth: 2)
                                        )
                                        .shadow(radius: 5)
                                        .onTapGesture {
                                            showFullScreenImage = image
                                        }
                                        .overlay(alignment: .topTrailing) {
                                            Button(action: {
                                                if let index = selectedImages.firstIndex(of: image) {
                                                    selectedImages.remove(at: index)
                                                }
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.title2)
                                                    .foregroundColor(.white)
                                                    .background(Color.black.opacity(0.7))
                                                    .clipShape(Circle())
                                            }
                                            .padding(8)
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 270)
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: 250)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray, style: StrokeStyle(lineWidth: 1, dash: [5]))
                                )
                                .padding(.horizontal)
                            
                            VStack(spacing: 10) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("Bilder hinzufügen")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    // Bildauswahl-Buttons
                    HStack(spacing: 20) {
                        Button(action: { showCamera = true }) {
                            Label("Kamera", systemImage: "camera")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                        }
                        
                        Button(action: { showGallery = true }) {
                            Label("Galerie", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    .foregroundColor(.blue)
                    
                    // Umschaltbutton nur auf iPad
                    // Umschaltbutton NUR auf iPad
                    if DeviceHelper.isiPad {
                                        Button(action: toggleDrawingMode) {
                                            Label(isDrawingMode ? "Textmodus" : "Freihandmodus",
                                                  systemImage: isDrawingMode ? "keyboard" : "pencil.tip")
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(Color.blue.opacity(0.1))
                                                .cornerRadius(10)
                                        }
                                        .padding(.horizontal)
                                        .foregroundColor(.blue)
                                    }
                                    
                                    // Notizbereich
                                    VStack(alignment: .leading) {
                                        Text("Notiz")
                                            .font(.headline)
                                            .padding(.horizontal)
                                        
                                        if DeviceHelper.isiPhone || !isDrawingMode {
                                                                TextEditor(text: $notizText)
                                                                    .frame(height: 150)
                                                                    .padding()
                                                                    .background(Color.gray.opacity(0.1))
                                                                    .cornerRadius(12)
                                                                    .overlay(
                                                                        RoundedRectangle(cornerRadius: 12)
                                                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                                                    )
                                                                    .padding(.horizontal)
                                                                    .toolbar {
                                                                        ToolbarItemGroup(placement: .keyboard) {
                                                                            Spacer()
                                                                            Button("Fertig") {
                                                                                hideKeyboard()
                                                                            }
                                                                        }
                                                                    }
                                                            } else {
                                                                drawingView
                                                            }
                                    }
                    
                    // Aktionsbuttons
                    actionButtons
                    
                    // Gespeicherte Notizen
                    savedNotesView
                }
                .padding(.vertical)
                                .frame(maxWidth: .infinity)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    hideKeyboard()
                                }
            }
            .navigationTitle("Notizen")
            .sheet(isPresented: $showCamera) {
                CameraView { image in
                    if let image = image {
                        selectedImages.append(image)
                    }
                    showCamera = false
                }
                .edgesIgnoringSafeArea(.all)
            }
            .sheet(isPresented: $showGallery) {
                PhotoPicker { images in
                    selectedImages.append(contentsOf: images)
                    showGallery = false
                }
            }
            .fullScreenCover(item: $showFullScreenImage) { image in
                FullScreenImageView(image: image) {
                    showFullScreenImage = nil
                }
            }
            .alert("Notiz löschen", isPresented: $showDeleteAlert) {
                Button("Löschen", role: .destructive) {
                    if let note = noteToDelete {
                        deleteNote(note)
                    }
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Möchten Sie diese Notiz wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.")
            }
            .onAppear {
                loadNotes()
                if !DeviceHelper.isiPhone {
                    toolPicker.addObserver(canvasView)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                                keyboardHeight = keyboardFrame.height
                            }
                        }
                        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                            keyboardHeight = 0
                        }
        }
    }
    
    // MARK: - Subviews
    
    private var drawingView: some View {
        VStack {
            if !isDrawingFullscreen {
                Button(action: { isDrawingFullscreen = true }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .padding(8)
                        .background(Circle().fill(Color.blue.opacity(0.2)))
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 8)
            }
            
            ZStack {
                PencilKitView(
                    canvasView: $canvasView,
                    toolPicker: toolPicker,
                    isFullscreen: $isDrawingFullscreen
                )
                .frame(height: isDrawingFullscreen ? UIScreen.main.bounds.height - 200 : 300)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                
                if isDrawingFullscreen {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: { isDrawingFullscreen = false }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .background(Circle().fill(Color.black.opacity(0.6)))
                            }
                        }
                        Spacer()
                    }
                    .padding()
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var actionButtons: some View {
        HStack(spacing: 20) {
            if editingNote != nil {
                Button(action: cancelEditing) {
                    Text("Abbrechen")
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                }
                .contentShape(Rectangle()) // Sorgt für volle Klickfläche
            }
            
            Button(action: saveNote) {
                Text(editingNote != nil ? "Aktualisieren" : "Speichern")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .contentShape(Rectangle())
        }
        .padding(.horizontal)
        .buttonStyle(.plain) // Beibehaltung des gewünschten Button-Stils
    }
    
    private var savedNotesView: some View {
        Group {
            if !savedNotes.isEmpty {
                Text("Gespeicherte Notizen")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
            }
            
            LazyVStack(spacing: 20) {
                ForEach(savedNotes) { note in
                    noteCardView(note: note)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func noteCardView(note: Note) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            if let imagesData = note.imagesData, !imagesData.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(imagesData, id: \.self) { imageData in
                            if let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 180, height: 200)
                                    .cornerRadius(10)
                                    .onTapGesture {
                                        showFullScreenImage = uiImage
                                    }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 220)
            }
            
            if let drawingData = note.drawingData,
               let drawing = try? PKDrawing(data: drawingData),
               !drawing.strokes.isEmpty {
                DrawingView(drawing: drawing)
                    .frame(height: 200)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal, 5)
            }
            
            if !note.text.isEmpty {
                Text(note.text)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal, 5)
            }
            
            HStack {
                Text(note.createdAt.formatted())
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: { editNote(note) }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
                
                Button(role: .destructive) {
                    noteToDelete = note
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Computed Properties
    
    private var saveButtonDisabled: Bool {
        return false
    }
    
    // MARK: - Functions
    
    private func toggleDrawingMode() {
        isDrawingMode.toggle()
        if !isDrawingMode {
            isDrawingFullscreen = false
        }
    }
    
    private func saveNote() {
        let imagesData = selectedImages.compactMap { $0.jpegData(compressionQuality: 0.7) }
        let drawingData = isDrawingMode && !canvasView.drawing.strokes.isEmpty ? canvasView.drawing.dataRepresentation() : nil
        
        if let editingNote = editingNote,
           let index = savedNotes.firstIndex(where: { $0.id == editingNote.id }) {
            savedNotes[index] = Note(
                id: editingNote.id,
                text: notizText,
                imagesData: imagesData.isEmpty ? nil : imagesData,
                drawingData: drawingData,
                createdAt: editingNote.createdAt
            )
        } else {
            let newNote = Note(
                text: notizText,
                imagesData: imagesData.isEmpty ? nil : imagesData,
                drawingData: drawingData,
                createdAt: Date()
            )
            savedNotes.append(newNote)
        }
        
        saveNotes()
        cancelEditing()
    }
    
    private func editNote(_ note: Note) {
        editingNote = note
        notizText = note.text
        selectedImages = note.imagesData?.compactMap { UIImage(data: $0) } ?? []
        
        if let drawingData = note.drawingData,
           let drawing = try? PKDrawing(data: drawingData) {
            canvasView.drawing = drawing
            if !DeviceHelper.isiPhone {
                isDrawingMode = true
            }
        } else {
            canvasView.drawing = PKDrawing()
            isDrawingMode = false
        }
    }
    
    private func deleteNote(_ note: Note) {
        if let index = savedNotes.firstIndex(where: { $0.id == note.id }) {
            savedNotes.remove(at: index)
            saveNotes()
        }
    }
    
    private func cancelEditing() {
        editingNote = nil
        notizText = ""
        selectedImages = []
        canvasView.drawing = PKDrawing()
        isDrawingMode = false
        isDrawingFullscreen = false
    }
    
    private func saveNotes() {
        // Sortiere die Notizen absteigend nach Erstellungsdatum
        savedNotes.sort { $0.createdAt > $1.createdAt }
        
        if let encoded = try? JSONEncoder().encode(savedNotes) {
            UserDefaults.standard.set(encoded, forKey: "savedNotes")
        }
    }

    private func loadNotes() {
        if let data = UserDefaults.standard.data(forKey: "savedNotes"),
           let decoded = try? JSONDecoder().decode([Note].self, from: data) {
            // Die Notizen sind bereits in saveNotes() sortiert worden
            savedNotes = decoded
        }
    }
}

// MARK: - Hilfsstrukturen

struct PencilKitView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    let toolPicker: PKToolPicker
    @Binding var isFullscreen: Bool
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .pencilOnly
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 10)
        canvasView.isScrollEnabled = true
        canvasView.minimumZoomScale = 1.0
        canvasView.maximumZoomScale = 3.0
        canvasView.contentSize = CGSize(width: 1000, height: 2000)
        canvasView.backgroundColor = .systemGray6
        
        if !isFullscreen {
            toolPicker.setVisible(true, forFirstResponder: canvasView)
            toolPicker.addObserver(canvasView)
        }
        
        DispatchQueue.main.async {
            canvasView.becomeFirstResponder()
        }
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.drawingPolicy = .pencilOnly
        uiView.isScrollEnabled = true
        if isFullscreen {
            uiView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 200)
        }
    }
}

struct DrawingView: UIViewRepresentable {
    let drawing: PKDrawing
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.drawing = drawing
        canvasView.isUserInteractionEnabled = false
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.drawing = drawing
    }
}

struct Note: Identifiable, Codable {
    let id: UUID
    let text: String
    let imagesData: [Data]?
    let drawingData: Data?
    let createdAt: Date
    
    init(id: UUID = UUID(), text: String, imagesData: [Data]?, drawingData: Data? = nil, createdAt: Date = Date()) {
        self.id = id
        self.text = text
        self.imagesData = imagesData
        self.drawingData = drawingData
        self.createdAt = createdAt
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    var completion: (UIImage?) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.completion(image)
            } else {
                parent.completion(nil)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.completion(nil)
            picker.dismiss(animated: true)
        }
    }
}

struct PhotoPicker: UIViewControllerRepresentable {
    var completion: ([UIImage]) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 0 // 0 = unlimited selection
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            let group = DispatchGroup()
            var images = [UIImage]()
            
            for result in results {
                group.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                    if let image = object as? UIImage {
                        images.append(image)
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self.parent.completion(images)
            }
        }
    }
}

struct FullScreenImageView: View {
    let image: UIImage
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .gesture(
                    TapGesture()
                        .onEnded { _ in
                            onDismiss()
                        }
                )
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                Spacer()
            }
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    var completion: (UIImage?) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView
        
        init(parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                 didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.completion(image)
            } else {
                parent.completion(nil)
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.completion(nil)
        }
    }
}

func checkCameraPermissions() {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized: break
    case .notDetermined:
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if !granted {
                // Zeige Hinweis an den Benutzer
            }
        }
    case .denied, .restricted:
        // Zeige Hinweis mit Link zu Einstellungen
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    @unknown default: break
    }
}

extension UIImage: Identifiable {
    public var id: String { UUID().uuidString }
}

// Keyboard-Hilfsfunktion
#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
