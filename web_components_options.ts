'use client';

import type { JobType } from '@you-pdf/core';

interface ToolOptionsProps {
  toolType: JobType;
  options: any;
  onOptionsChange: (options: any) => void;
}

export function ToolOptions({ toolType, options, onOptionsChange }: ToolOptionsProps) {
  const updateOption = (key: string, value: any) => {
    onOptionsChange({ ...options, [key]: value });
  };

  // Render different options based on tool type
  switch (toolType) {
    case 'compress-pdf':
      return (
        <div className="mt-6 p-4 bg-gray-50 rounded-lg">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Compression Quality
          </label>
          <select
            value={options.quality || 'medium'}
            onChange={(e) => updateOption('quality', e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          >
            <option value="high">High (better quality, larger file)</option>
            <option value="medium">Medium (balanced)</option>
            <option value="low">Low (smaller file, lower quality)</option>
          </select>
        </div>
      );

    case 'split-pdf':
      return (
        <div className="mt-6 p-4 bg-gray-50 rounded-lg">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Page Ranges (e.g., "1-3, 5, 7-9")
          </label>
          <input
            type="text"
            value={options.ranges || ''}
            onChange={(e) => updateOption('ranges', e.target.value)}
            placeholder="Leave empty to split each page"
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          />
        </div>
      );

    case 'rotate-pdf':
      return (
        <div className="mt-6 p-4 bg-gray-50 rounded-lg">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Rotation Angle
          </label>
          <select
            value={options.rotation || 90}
            onChange={(e) => updateOption('rotation', parseInt(e.target.value))}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          >
            <option value={90}>90° Clockwise</option>
            <option value={180}>180°</option>
            <option value={270}>90° Counter-clockwise</option>
          </select>
        </div>
      );

    case 'add-watermark':
      return (
        <div className="mt-6 p-4 bg-gray-50 rounded-lg space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Watermark Text
            </label>
            <input
              type="text"
              value={options.text || 'CONFIDENTIAL'}
              onChange={(e) => updateOption('text', e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Position
            </label>
            <select
              value={options.position || 'center'}
              onChange={(e) => updateOption('position', e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="center">Center</option>
              <option value="top-left">Top Left</option>
              <option value="top-right">Top Right</option>
              <option value="bottom-left">Bottom Left</option>
              <option value="bottom-right">Bottom Right</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Opacity: {options.opacity || 0.3}
            </label>
            <input
              type="range"
              min="0.1"
              max="1"
              step="0.1"
              value={options.opacity || 0.3}
              onChange={(e) => updateOption('opacity', parseFloat(e.target.value))}
              className="w-full"
            />
          </div>
        </div>
      );

    case 'ai-summarize':
      return (
        <div className="mt-6 p-4 bg-gray-50 rounded-lg space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Summary Length
            </label>
            <select
              value={options.length || 'medium'}
              onChange={(e) => updateOption('length', e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="short">Short (2-3 sentences)</option>
              <option value="medium">Medium (1-2 paragraphs)</option>
              <option value="long">Long (detailed)</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Format
            </label>
            <select
              value={options.format || 'paragraph'}
              onChange={(e) => updateOption('format', e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="paragraph">Paragraph</option>
              <option value="bullets">Bullet Points</option>
            </select>
          </div>
        </div>
      );

    case 'ai-translate':
      return (
        <div className="mt-6 p-4 bg-gray-50 rounded-lg">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Target Language
          </label>
          <select
            value={options.targetLang || 'Spanish'}
            onChange={(e) => updateOption('targetLang', e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          >
            <option value="Spanish">Spanish</option>
            <option value="French">French</option>
            <option value="German">German</option>
            <option value="Chinese">Chinese</option>
            <option value="Japanese">Japanese</option>
            <option value="Hindi">Hindi</option>
            <option value="Arabic">Arabic</option>
          </select>
        </div>
      );

    case 'ai-chat':
      return (
        <div className="mt-6 p-4 bg-gray-50 rounded-lg">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Your Question
          </label>
          <textarea
            value={options.question || ''}
            onChange={(e) => updateOption('question', e.target.value)}
            placeholder="Ask anything about the document..."
            rows={3}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          />
        </div>
      );

    case 'ai-quiz-generator':
      return (
        <div className="mt-6 p-4 bg-gray-50 rounded-lg">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Number of Questions
          </label>
          <input
            type="number"
            min="5"
            max="50"
            value={options.numQuestions || 10}
            onChange={(e) => updateOption('numQuestions', parseInt(e.target.value))}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          />
        </div>
      );

    case 'ai-flashcards':
      return (
        <div className="mt-6 p-4 bg-gray-50 rounded-lg">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Number of Flashcards
          </label>
          <input
            type="number"
            min="10"
            max="100"
            value={options.numCards || 20}
            onChange={(e) => updateOption('numCards', parseInt(e.target.value))}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          />
        </div>
      );

    default:
      return null;
  }
}