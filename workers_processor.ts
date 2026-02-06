import type { SupabaseClient } from '@supabase/supabase-js';
import type { PDFEngine } from '@you-pdf/pdf-engine';
import type { AIEngine } from '@you-pdf/ai-engine';
import type { Job } from '@you-pdf/core';
import { config } from '@you-pdf/core';

export async function processJob(
  jobData: Job,
  supabase: SupabaseClient,
  pdfEngine: PDFEngine,
  aiEngine: AIEngine,
  updateProgress: (progress: number) => void
) {
  
  // Update status to processing
  await updateJobStatus(supabase, jobData.id, 'processing', 10);
  updateProgress(10);

  let result: Buffer | Buffer[] | string | any;
  let outputUrls: string[] = [];

  try {
    switch (jobData.type) {
      // Core PDF Operations
      case 'merge-pdf':
        result = await pdfEngine.mergePDFs(jobData.input.files);
        outputUrls = [await uploadFile(supabase, jobData.user_id, result, 'merged.pdf')];
        break;

      case 'split-pdf':
        updateProgress(20);
        result = await pdfEngine.splitPDF(jobData.input.files[0], jobData.input.options || {});
        updateProgress(60);
        
        for (let i = 0; i < result.length; i++) {
          const url = await uploadFile(supabase, jobData.user_id, result[i], `page_${i + 1}.pdf`);
          outputUrls.push(url);
        }
        break;

      case 'compress-pdf':
        result = await pdfEngine.compressPDF(jobData.input.files[0], jobData.input.options?.quality || 'medium');
        outputUrls = [await uploadFile(supabase, jobData.user_id, result, 'compressed.pdf')];
        break;

      case 'rotate-pdf':
        result = await pdfEngine.rotatePDF(jobData.input.files[0], jobData.input.options?.rotation || 90);
        outputUrls = [await uploadFile(supabase, jobData.user_id, result, 'rotated.pdf')];
        break;

      case 'delete-pages':
        result = await pdfEngine.deletePages(jobData.input.files[0], jobData.input.options?.pages || []);
        outputUrls = [await uploadFile(supabase, jobData.user_id, result, 'edited.pdf')];
        break;

      case 'extract-pages':
        result = await pdfEngine.extractPages(jobData.input.files[0], jobData.input.options?.pages || []);
        outputUrls = [await uploadFile(supabase, jobData.user_id, result, 'extracted.pdf')];
        break;

      // Editing
      case 'add-watermark':
        updateProgress(30);
        result = await pdfEngine.addWatermark(jobData.input.files[0], {
          text: jobData.input.options?.text || 'CONFIDENTIAL',
          position: jobData.input.options?.position || 'center',
          opacity: jobData.input.options?.opacity || 0.3,
          rotation: jobData.input.options?.rotation || 45,
          fontSize: jobData.input.options?.fontSize || 48,
        });
        outputUrls = [await uploadFile(supabase, jobData.user_id, result, 'watermarked.pdf')];
        break;

      case 'add-page-numbers':
        result = await pdfEngine.addPageNumbers(jobData.input.files[0], {
          position: jobData.input.options?.position || 'bottom',
          align: jobData.input.options?.align || 'center',
          startFrom: jobData.input.options?.startFrom || 1,
          format: jobData.input.options?.format || 'Page {n}',
        });
        outputUrls = [await uploadFile(supabase, jobData.user_id, result, 'numbered.pdf')];
        break;

      // Conversion
      case 'pdf-to-images':
        updateProgress(20);
        result = await pdfEngine.pdfToImages(jobData.input.files[0]);
        updateProgress(60);
        
        for (let i = 0; i < result.length; i++) {
          const url = await uploadFile(supabase, jobData.user_id, result[i], `page_${i + 1}.jpg`);
          outputUrls.push(url);
        }
        break;

      case 'images-to-pdf':
        updateProgress(30);
        result = await pdfEngine.imagesToPDF(jobData.input.files);
        outputUrls = [await uploadFile(supabase, jobData.user_id, result, 'images.pdf')];
        break;

      case 'extract-text':
        updateProgress(40);
        result = await pdfEngine.extractText(jobData.input.files[0]);
        const textBuffer = Buffer.from(result as string, 'utf-8');
        outputUrls = [await uploadFile(supabase, jobData.user_id, textBuffer, 'extracted.txt')];
        break;

      // AI Tools
      case 'ai-summarize':
        updateProgress(30);
        const textToSummarize = await pdfEngine.extractText(jobData.input.files[0]);
        updateProgress(50);
        
        result = await aiEngine.summarize(textToSummarize, jobData.input.options);
        updateProgress(80);
        
        const summaryBuffer = Buffer.from(result as string, 'utf-8');
        outputUrls = [await uploadFile(supabase, jobData.user_id, summaryBuffer, 'summary.txt')];
        break;

      case 'ai-translate':
        updateProgress(30);
        const textToTranslate = await pdfEngine.extractText(jobData.input.files[0]);
        updateProgress(50);
        
        result = await aiEngine.translate(
          textToTranslate,
          jobData.input.options?.targetLang || 'Spanish',
          jobData.input.options
        );
        updateProgress(80);
        
        const translationBuffer = Buffer.from(result as string, 'utf-8');
        outputUrls = [await uploadFile(supabase, jobData.user_id, translationBuffer, 'translated.txt')];
        break;

      case 'ai-chat':
        updateProgress(30);
        const textForChat = await pdfEngine.extractText(jobData.input.files[0]);
        updateProgress(50);
        
        result = await aiEngine.chatWithPDF(
          textForChat,
          jobData.input.options?.question || '',
          jobData.input.options
        );
        updateProgress(80);
        
        await updateJobStatus(supabase, jobData.id, 'completed', 100, {
          urls: [],
          data: { answer: result }
        });
        return;

      case 'ai-analyze-resume':
        updateProgress(30);
        const resumeText = await pdfEngine.extractText(jobData.input.files[0]);
        updateProgress(50);
        
        result = await aiEngine.analyzeResume(resumeText, jobData.input.options?.jobDescription);
        updateProgress(80);
        
        await updateJobStatus(supabase, jobData.id, 'completed', 100, {
          urls: [],
          data: result
        });
        return;

      case 'ai-book-notes':
        updateProgress(30);
        const bookText = await pdfEngine.extractText(jobData.input.files[0]);
        updateProgress(50);
        
        result = await aiEngine.bookNotes(bookText);
        updateProgress(80);
        
        const notesBuffer = Buffer.from(result as string, 'utf-8');
        outputUrls = [await uploadFile(supabase, jobData.user_id, notesBuffer, 'notes.txt')];
        break;

      case 'ai-quiz-generator':
        updateProgress(30);
        const quizText = await pdfEngine.extractText(jobData.input.files[0]);
        updateProgress(50);
        
        result = await aiEngine.quizFromText(quizText, jobData.input.options?.numQuestions || 10);
        updateProgress(80);
        
        await updateJobStatus(supabase, jobData.id, 'completed', 100, {
          urls: [],
          data: result
        });
        return;

      case 'ai-flashcards':
        updateProgress(30);
        const flashcardText = await pdfEngine.extractText(jobData.input.files[0]);
        updateProgress(50);
        
        result = await aiEngine.generateFlashcards(flashcardText, jobData.input.options?.numCards || 20);
        updateProgress(80);
        
        await updateJobStatus(supabase, jobData.id, 'completed', 100, {
          urls: [],
          data: result
        });
        return;

      case 'invoice-parser':
        updateProgress(30);
        const invoiceText = await pdfEngine.extractText(jobData.input.files[0]);
        updateProgress(50);
        
        result = await aiEngine.parseInvoice(invoiceText);
        updateProgress(80);
        
        await updateJobStatus(supabase, jobData.id, 'completed', 100, {
          urls: [],
          data: result
        });
        return;

      case 'contract-extractor':
        updateProgress(30);
        const contractText = await pdfEngine.extractText(jobData.input.files[0]);
        updateProgress(50);
        
        result = await aiEngine.extractContract(contractText);
        updateProgress(80);
        
        await updateJobStatus(supabase, jobData.id, 'completed', 100, {
          urls: [],
          data: result
        });
        return;

      default:
        throw new Error(`Unknown job type: ${jobData.type}`);
    }

    updateProgress(90);

    // Update job with output
    await updateJobStatus(supabase, jobData.id, 'completed', 100, {
      urls: outputUrls,
    });

  } catch (error: any) {
    console.error(`Error processing job ${jobData.id}:`, error);
    await updateJobStatus(supabase, jobData.id, 'failed', 0, null, error.message);
    throw error;
  }
}

async function uploadFile(
  supabase: SupabaseClient,
  userId: string,
  buffer: Buffer,
  filename: string
): Promise<string> {
  const path = `${userId}/${Date.now()}_${filename}`;
  
  const { data, error } = await supabase.storage
    .from(config.buckets.outputs)
    .upload(path, buffer, {
      contentType: filename.endsWith('.pdf') ? 'application/pdf' : 
                   filename.endsWith('.txt') ? 'text/plain' :
                   filename.endsWith('.jpg') ? 'image/jpeg' : 'application/octet-stream',
    });

  if (error) throw error;

  const { data: urlData } = supabase.storage
    .from(config.buckets.outputs)
    .getPublicUrl(path);

  return urlData.publicUrl;
}

async function updateJobStatus(
  supabase: SupabaseClient,
  jobId: string,
  status: string,
  progress: number,
  output: any = null,
  error: string | null = null
) {
  const updates: any = {
    status,
    progress,
    updated_at: new Date().toISOString(),
  };

  if (output) updates.output = output;
  if (error) updates.error = error;

  const { error: updateError } = await supabase
    .from('jobs')
    .update(updates)
    .eq('id', jobId);

  if (updateError) {
    console.error('Failed to update job status:', updateError);
  }
}