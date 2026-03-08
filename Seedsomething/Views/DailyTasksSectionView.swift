import SwiftUI

struct DailyTasksSectionView: View {
    @State var tasks: [DailyTask]

    var body: some View {
        VStack {
            List {
                ForEach(tasks, id: \ .id) { task in
                    HStack {
                        Text(task.title)
                        Spacer()
                        Button(action: {
                            // Toggle done status
                        }) {
                            Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                        }
                    }
                }
            }
            .progressViewStyle(LinearProgressViewStyle()) // 使用 LinearProgressViewStyle
        }
    }
}