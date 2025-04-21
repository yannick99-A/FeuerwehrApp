import SwiftUI
import PhotosUI

struct NotizenView: View {
    @State private var notizText: String = ""
    @State private var savedNotes: [Note] = []
    @State private var selectedImages: [UIImage] = []
    @State private var showImagePicker = false
    @State private var isCamera = false
    @State private var showFullScreenImage: UIImage? = nil
    @State private var editingNote: Note? = nil
    @State private var showCamera = false // Separate Variable für Kamera
    @State private var showGallery = false // Separate Variable für Galerie
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Bildbereich (vergrößert)
                    if !selectedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(selectedImages, id: \.self) { image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 200, height: 250)  // Größere Dimensionen
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
                        .frame(height: 270)  // Höherer Container
                    } else {
                        // Platzhalter für Bilder
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
                        Button(action: {
                            showCamera = true
                        }) {
                            Label("Kamera", systemImage: "camera")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                        }
                        
                        Button(action: {
                            showGallery = true
                        }) {
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
                    
                    // Notizbereich
                    VStack(alignment: .leading) {
                        Text("Notiz")
                            .font(.headline)
                            .padding(.horizontal)
                        TextEditor(text: $notizText)
                            .frame(height: 150)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    
                    // Aktionsbuttons
                    HStack(spacing: 20) {
                        if editingNote != nil {
                            Button("Abbrechen") {
                                cancelEditing()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        Button(editingNote != nil ? "Aktualisieren" : "Speichern") {
                            saveNote()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(notizText.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .disabled(notizText.isEmpty)
                    }
                    .padding(.horizontal)
                    
                    // Gespeicherte Notizen
                    if !savedNotes.isEmpty {
                        Text("Gespeicherte Notizen")
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top)
                    }
                    
                    LazyVStack(spacing: 20) {
                        ForEach(savedNotes) { note in
                            VStack(alignment: .leading, spacing: 15) {
                                // Bilder der Notiz
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
                                
                                // Notiztext
                                Text(note.text)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(10)
                                    .padding(.horizontal, 5)
                                
                                // Metadaten und Aktionen
                                HStack {
                                    Text(note.createdAt.formatted())
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        editNote(note)
                                    }) {
                                        Image(systemName: "pencil")
                                            .foregroundColor(.blue)
                                    }
                                    
                                    Button(role: .destructive) {
                                        deleteNote(note)
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
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
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
            .onAppear {
                loadNotes()
            }
        }
    }
    
    private func saveNote() {
        let imagesData = selectedImages.compactMap { $0.jpegData(compressionQuality: 0.7) }
        
        if let editingNote = editingNote,
           let index = savedNotes.firstIndex(where: { $0.id == editingNote.id }) {
            // Update existing note
            savedNotes[index] = Note(
                id: editingNote.id,
                text: notizText,
                imagesData: imagesData.isEmpty ? nil : imagesData,
                createdAt: editingNote.createdAt
            )
        } else {
            // Create new note
            let newNote = Note(
                text: notizText,
                imagesData: imagesData.isEmpty ? nil : imagesData,
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
    }
    
    private func saveNotes() {
        if let encoded = try? JSONEncoder().encode(savedNotes) {
            UserDefaults.standard.set(encoded, forKey: "savedNotes")
        }
    }
    
    private func loadNotes() {
        if let data = UserDefaults.standard.data(forKey: "savedNotes"),
           let decoded = try? JSONDecoder().decode([Note].self, from: data) {
            savedNotes = decoded.sorted { $0.createdAt > $1.createdAt }
        }
    }
}

struct Note: Identifiable, Codable {
    let id: UUID
    let text: String
    let imagesData: [Data]?
    let createdAt: Date
    
    init(id: UUID = UUID(), text: String, imagesData: [Data]?, createdAt: Date = Date()) {
        self.id = id
        self.text = text
        self.imagesData = imagesData
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

// In der AppDelegate oder SceneDelegate (wichtig für Berechtigungen):
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
