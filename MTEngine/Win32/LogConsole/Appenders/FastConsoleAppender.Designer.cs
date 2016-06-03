namespace LogConsole.Appenders
{
    partial class FastConsoleAppender
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.vScrollBar = new System.Windows.Forms.VScrollBar();
            this.SuspendLayout();
            // 
            // vScrollBar
            // 
            this.vScrollBar.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom)
                        | System.Windows.Forms.AnchorStyles.Right)));
            this.vScrollBar.Location = new System.Drawing.Point(642, 0);
            this.vScrollBar.Name = "vScrollBar";
            this.vScrollBar.Size = new System.Drawing.Size(16, 303);
            this.vScrollBar.TabIndex = 0;
            this.vScrollBar.Scroll += new System.Windows.Forms.ScrollEventHandler(this.vScrollBar_Scroll);
            // 
            // FastConsoleAppender
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.Color.Black;
            this.ClientSize = new System.Drawing.Size(658, 303);
            this.Controls.Add(this.vScrollBar);
            this.Name = "FastConsoleAppender";
            this.Text = "Form1";
            this.Load += new System.EventHandler(this.FastConsole_Load);
            this.ResizeBegin += new System.EventHandler(this.FastConsole_ResizeBegin);
            this.MouseUp += new System.Windows.Forms.MouseEventHandler(this.FastConsole_MouseUp);
            this.MouseDown += new System.Windows.Forms.MouseEventHandler(this.FastConsole_MouseDown);
            this.FormClosing += new System.Windows.Forms.FormClosingEventHandler(this.FastConsole_FormClosing);
            this.Resize += new System.EventHandler(this.FastConsole_Resize);
            this.MouseMove += new System.Windows.Forms.MouseEventHandler(this.FastConsole_MouseMove);
            this.KeyDown += new System.Windows.Forms.KeyEventHandler(this.FastConsole_KeyDown);
            this.ResizeEnd += new System.EventHandler(this.FastConsole_ResizeEnd);
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.VScrollBar vScrollBar;

    }
}