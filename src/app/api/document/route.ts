import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  try {
    const formData = await request.formData();
    const file = formData.get('file') as File | null;

    if (!file) {
      return NextResponse.json({ error: 'file is required' }, { status: 400 });
    }

    const buffer = Buffer.from(await file.arrayBuffer());
    const fileName = file.name;
    const fileType = fileName.split('.').pop()?.toLowerCase() ?? '';

    let extractedText = '';

    if (fileType === 'txt') {
      extractedText = buffer.toString('utf-8');
    } else if (fileType === 'pdf') {
      const pdfParse = (await import('pdf-parse')).default;
      const pdfData = await pdfParse(buffer);
      extractedText = pdfData.text;
    } else if (fileType === 'docx' || fileType === 'doc') {
      const mammoth = await import('mammoth');
      const result = await mammoth.extractRawText({ buffer });
      extractedText = result.value;
    } else if (['png', 'jpg', 'jpeg', 'webp'].includes(fileType)) {
      const Tesseract = await import('tesseract.js');
      const { data } = await Tesseract.recognize(buffer, 'eng+urd');
      extractedText = data.text;
    } else {
      return NextResponse.json({ error: 'Unsupported file type' }, { status: 400 });
    }

    if (!extractedText.trim()) {
      return NextResponse.json({ error: 'No text could be extracted from the file' }, { status: 400 });
    }

    return NextResponse.json({
      filename: fileName,
      fileType,
      originalText: extractedText,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
